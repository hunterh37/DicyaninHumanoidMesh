import RealityKit
import simd

@MainActor
public final class HumanoidEntity {

    // MARK: - Skeleton construction
    //
    // The figure is a true joint hierarchy, not a bag of sibling meshes:
    //
    //   humanoid (root)
    //   ├─ joint_torso            (pivots at the hips; carries head + both arms)
    //   │  ├─ torso mesh
    //   │  ├─ head mesh
    //   │  ├─ joint_upperArm_L → upperArm mesh
    //   │  └─ joint_upperArm_R → … (mirror)
    //   ├─ joint_thigh_L → thigh mesh
    //   └─ joint_thigh_R → … (mirror)
    //
    // Each limb mesh hangs *below* its joint, so rotating a joint swings the
    // whole sub-chain (forearm + hand follow the upper arm, etc.). Joint world
    // positions are derived from the original part offsets so the rest ("A") pose
    // looks identical to before — painting UVs and collisions are unaffected.

    public static func create(pose: PosePreset = .aPose) -> Entity {
        let root = Entity("humanoid")
        root.position = [0, 0, 0]

        // Torso pivots at its base so leaning carries the head and arms with it.
        let torsoJointWorld: SIMD3<Float> = HumanoidMesh.bodyPartOffset(.torso) - [0, torsoBottomExtent, 0]
        let torsoJoint = makeJoint("joint_torso")
        torsoJoint.position = torsoJointWorld
        root.addChild(torsoJoint)

        // Torso and head ride directly on the torso joint (head doesn't articulate).
        let torsoMesh = makePart(.torso)
        torsoMesh.position = HumanoidMesh.bodyPartOffset(.torso) - torsoJointWorld
        torsoJoint.addChild(torsoMesh)

        let neckMesh = makePart(.neck)
        neckMesh.position = HumanoidMesh.bodyPartOffset(.neck) - torsoJointWorld
        torsoJoint.addChild(neckMesh)

        let headMesh = makePart(.head)
        headMesh.position = HumanoidMesh.bodyPartOffset(.head) - torsoJointWorld
        torsoJoint.addChild(headMesh)

        // Arms hang from the shoulders, which hang from the torso. Each arm is a
        // two-segment chain (upper arm → forearm) so it bends at the elbow.
        buildChain([.upperArm_L, .forearm_L], parentJoint: torsoJoint, parentJointWorld: torsoJointWorld)
        buildChain([.upperArm_R, .forearm_R], parentJoint: torsoJoint, parentJointWorld: torsoJointWorld)

        // Legs hang from the hips on the root (so a torso lean doesn't drag them).
        // Two segments (thigh → shin) so the leg bends at the knee.
        buildChain([.thigh_L, .shin_L], parentJoint: root, parentJointWorld: [0, 0, 0])
        buildChain([.thigh_R, .shin_R], parentJoint: root, parentJointWorld: [0, 0, 0])

        applyPose(pose, to: root)
        return root
    }

    /// Builds a nested joint→mesh chain. Each part gets a `joint_<part>` pivot at
    /// the top of the segment, with the mesh parented below it at its original
    /// world position (so the A-pose is preserved exactly).
    private static func buildChain(
        _ parts: [BodyPart],
        parentJoint: Entity,
        parentJointWorld: SIMD3<Float>
    ) {
        var parent = parentJoint
        var parentWorld = parentJointWorld
        for part in parts {
            let jointWorld = jointWorldPos(part)
            let joint = makeJoint("joint_" + part.rawValue)
            joint.position = jointWorld - parentWorld
            parent.addChild(joint)

            let mesh = makePart(part)
            mesh.position = HumanoidMesh.bodyPartOffset(part) - jointWorld
            joint.addChild(mesh)

            parent = joint
            parentWorld = jointWorld
        }
    }

    private static func makeJoint(_ name: String) -> Entity {
        Entity(name)
    }

    /// Creates a single painted, collidable body-part mesh entity (named with the
    /// raw BodyPart value, which the paint system looks up).
    private static func makePart(_ part: BodyPart) -> Entity {
        let child = Entity(part.rawValue)

        let blankImage = PaintTexture.createBlankCGImage()
        let texture = try! TextureResource.generate(from: blankImage, options: .init(semantic: .color))
        var material = PhysicallyBasedMaterial()
        material.baseColor = PhysicallyBasedMaterial.BaseColor(texture: .init(texture))
        material.roughness = 0.6
        material.metallic = 0.0

        child.components.set(ModelComponent(
            mesh: HumanoidMesh.generateBodyPart(part),
            materials: [material]
        ))
        child.components.set(CollisionComponent(shapes: [HumanoidMesh.collisionShape(for: part)], isStatic: true))
        child.components.set(InputTargetComponent())
        child.components.set(PaintComponent())
        return child
    }

    // MARK: - Joint geometry

    /// World-space pivot point for a limb segment in the rest pose: the top end of
    /// the part, so the segment swings from its proximal joint like a real limb.
    private static func jointWorldPos(_ part: BodyPart) -> SIMD3<Float> {
        HumanoidMesh.bodyPartOffset(part) + [0, topExtent(part), 0]
    }

    /// Distance from a part's center to its top end (where its joint sits).
    private static func topExtent(_ part: BodyPart) -> Float {
        switch part {
        case .upperArm_L, .upperArm_R: return 0.172   // cyl/2 (0.10) + topRadius (0.072)
        case .forearm_L, .forearm_R:   return 0.186   // cyl/2 (0.12) + topRadius (0.066)
        case .thigh_L, .thigh_R:       return 0.224   // cyl/2 (0.13) + topRadius (0.094)
        case .shin_L, .shin_R:         return 0.236   // cyl/2 (0.15) + topRadius (0.086)
        case .head, .neck, .torso:     return 0.0
        }
    }

    private static let torsoBottomExtent: Float = 0.33  // cyl/2 (0.15) + bottomRadius (0.18)

    // MARK: - Posing

    /// Rotation axis for a joint: arms swing in the frontal plane (Z), legs in the
    /// sagittal plane (X).
    nonisolated public static func rotationAxis(for part: BodyPart) -> SIMD3<Float> {
        switch part {
        case .thigh_L, .thigh_R, .shin_L, .shin_R, .forearm_L, .forearm_R:
            // Legs and knees bend in the sagittal plane; elbows bend forward.
            return [1, 0, 0]
        default:
            // Shoulders and torso swing in the frontal plane.
            return [0, 0, 1]
        }
    }

    public static func applyPose(_ pose: PosePreset, to root: Entity) {
        applyAngles(pose.jointAngles, to: root)
    }

    /// Drives the skeleton by rotating each joint pivot. Used both for instant
    /// pose changes and for per-frame pose transitions.
    public static func applyAngles(_ angles: JointAngles, to root: Entity) {
        applyAngles(angles, to: root, parts: BodyPart.allCases)
    }

    /// Applies angles to a subset of joints only, so callers can layer other
    /// drivers (hand-tracking arm aim, head look) on top of locomotion.
    nonisolated public static func applyAngles(_ angles: JointAngles, to root: Entity, parts: [BodyPart]) {
        for part in parts {
            guard let joint = root.findEntity(named: "joint_" + part.rawValue) else { continue }
            joint.orientation = simd_quatf(angle: angles[part], axis: rotationAxis(for: part))
        }
    }
}
