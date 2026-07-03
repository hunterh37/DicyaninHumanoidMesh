import RealityKit
import simd

#if canImport(UIKit)
import UIKit
#endif

public enum HumanoidMesh {

    // MARK: - Part shape definitions
    //
    // Instead of RealityKit's stock primitives, every body part (except the flat
    // feet) is a procedurally-generated, smoothly-tapered "organic capsule": a tube
    // whose radius eases from one end to the other, capped with hemispheres. Heads
    // and hands are the degenerate zero-length case (pure spheres). Because the caps
    // are rounded and the parts overlap at every joint, the assembled figure reads
    // as one continuous rounded clay humanoid rather than a stack of cylinders.

    private enum UVMode { case spherical, cylindrical, planar }

    private struct Shape {
        var cylHeight: Float      // length of the straight (tapered) mid-section
        var topRadius: Float
        var bottomRadius: Float
        var scaleX: Float = 1     // cross-section width multiplier
        var scaleZ: Float = 1     // cross-section depth multiplier (flattens front/back)
        var uv: UVMode
    }

    private static func shape(for part: BodyPart) -> Shape {
        switch part {
        case .head:
            // Large rounded ball.
            return Shape(cylHeight: 0, topRadius: 0.17, bottomRadius: 0.17, uv: .spherical)
        case .neck:
            // Short stub that the head sinks onto.
            return Shape(cylHeight: 0.025, topRadius: 0.072, bottomRadius: 0.072, uv: .cylindrical)
        case .torso:
            // Inverted-triangle build: broad rounded shoulders tapering down to a
            // narrow waist/hips, flattened front-to-back (mecha-chameleon torso).
            return Shape(cylHeight: 0.30, topRadius: 0.275, bottomRadius: 0.18, scaleZ: 0.60, uv: .planar)
        case .upperArm_L, .upperArm_R:
            // Straight rounded segment. The bottom radius equals the forearm top
            // radius, and the segments are laid out so their straight walls meet
            // exactly while the rounded caps telescope inside one another, leaving
            // no visible elbow seam.
            return Shape(cylHeight: 0.20, topRadius: 0.072, bottomRadius: 0.066, uv: .cylindrical)
        case .forearm_L, .forearm_R:
            return Shape(cylHeight: 0.24, topRadius: 0.066, bottomRadius: 0.050, uv: .cylindrical)
        case .thigh_L, .thigh_R:
            return Shape(cylHeight: 0.26, topRadius: 0.094, bottomRadius: 0.086, uv: .cylindrical)
        case .shin_L, .shin_R:
            return Shape(cylHeight: 0.30, topRadius: 0.086, bottomRadius: 0.068, uv: .cylindrical)
        }
    }

    // MARK: - Mesh generation

    public static func generateBodyPart(_ part: BodyPart) -> MeshResource {
        return generateOrganicPart(shape(for: part))
    }

    /// Builds a tapered, hemisphere-capped surface of revolution centered at the
    /// local origin, with texture coordinates matching `PaintSystem.computeUV` so
    /// brush strokes land where the user taps.
    private static func generateOrganicPart(_ s: Shape) -> MeshResource {
        let radialSeg = 28
        let capRings = 7
        let sideRings = s.cylHeight > 0 ? 5 : 0

        let halfH = s.cylHeight / 2
        let slope = s.cylHeight > 0 ? (s.topRadius - s.bottomRadius) / s.cylHeight : 0

        // Bounds (must match `bounds(for:)`) used for cylindrical/planar UVs.
        let maxRX = max(s.topRadius, s.bottomRadius) * s.scaleX
        let minY = -(halfH + s.bottomRadius)
        let maxY = halfH + s.topRadius

        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []

        // A "ring" is a circle of vertices at a given height; poles are degenerate
        // rings of radius ~0. We emit rings bottom→top and stitch quads between them.
        struct Ring { var y: Float; var radius: Float; var ny: Float; var isHemi: Bool; var center: Float }
        var rings: [Ring] = []

        // Bottom hemisphere: phi -90°→0°
        for i in 0...capRings {
            let phi = -Float.pi / 2 + (Float.pi / 2) * Float(i) / Float(capRings)
            rings.append(Ring(y: -halfH + s.bottomRadius * sin(phi),
                              radius: s.bottomRadius * cos(phi),
                              ny: sin(phi), isHemi: true, center: -halfH))
        }
        // Tapered side: interior rings between the two cap seams
        for k in stride(from: 1, through: sideRings, by: 1) {
            let t = Float(k) / Float(sideRings + 1)
            rings.append(Ring(y: -halfH + s.cylHeight * t,
                              radius: s.bottomRadius + (s.topRadius - s.bottomRadius) * t,
                              ny: 0, isHemi: false, center: 0))
        }
        // Top hemisphere: phi 0°→90°
        for i in 0...capRings {
            let phi = (Float.pi / 2) * Float(i) / Float(capRings)
            rings.append(Ring(y: halfH + s.topRadius * sin(phi),
                              radius: s.topRadius * cos(phi),
                              ny: sin(phi), isHemi: true, center: halfH))
        }

        func uv(for p: SIMD3<Float>) -> SIMD2<Float> {
            switch s.uv {
            case .spherical:
                let n = simd_normalize(p)
                let u = 0.5 + atan2(n.z, n.x) / (2 * .pi)
                let v = 0.5 - asin(max(-1, min(1, n.y))) / .pi
                return SIMD2(u, v)
            case .cylindrical:
                let u = 0.5 + atan2(p.z, p.x) / (2 * .pi)
                let v = (p.y - minY) / (maxY - minY)
                return SIMD2(u, v)
            case .planar:
                let u = (p.x + maxRX) / (2 * maxRX)
                let v = (p.y - minY) / (maxY - minY)
                return SIMD2(u, v)
            }
        }

        // Emit ring vertices (seam duplicated at j == radialSeg for clean UVs).
        for ring in rings {
            for j in 0...radialSeg {
                let theta = 2 * Float.pi * Float(j) / Float(radialSeg)
                let cx = cos(theta), cz = sin(theta)
                let pos = SIMD3<Float>(ring.radius * cx * s.scaleX,
                                       ring.y,
                                       ring.radius * cz * s.scaleZ)
                // Normal: spherical on caps, cone-slope on the tapered side.
                var n: SIMD3<Float>
                if ring.isHemi {
                    let cphi = sqrt(max(0, 1 - ring.ny * ring.ny))
                    n = SIMD3<Float>(cphi * cx, ring.ny, cphi * cz)
                } else {
                    n = SIMD3<Float>(cx, -slope, cz)
                }
                n = simd_normalize(SIMD3<Float>(n.x / s.scaleX, n.y, n.z / s.scaleZ))
                positions.append(pos)
                normals.append(n)
                uvs.append(uv(for: pos))
            }
        }

        // Stitch quads between consecutive rings.
        var indices: [UInt32] = []
        let stride = radialSeg + 1
        for r in 0..<(rings.count - 1) {
            let a = r * stride
            let b = (r + 1) * stride
            for j in 0..<radialSeg {
                let a0 = UInt32(a + j), a1 = UInt32(a + j + 1)
                let b0 = UInt32(b + j), b1 = UInt32(b + j + 1)
                indices += [a0, b0, a1, a1, b0, b1]
            }
        }

        var desc = MeshDescriptor(name: "organicPart")
        desc.positions = MeshBuffer(positions)
        desc.normals = MeshBuffer(normals)
        desc.textureCoordinates = MeshBuffer(uvs)
        desc.primitives = .triangles(indices)
        return (try? MeshResource.generate(from: [desc])) ?? .generateSphere(radius: max(s.topRadius, s.bottomRadius))
    }

    // MARK: - Collision (approximate bounding volumes; hit-testing only)

    public static func collisionShape(for part: BodyPart) -> ShapeResource {
        let s = shape(for: part)
        // The mesh bounds are vertically asymmetric whenever topRadius != bottomRadius
        // (the apex sits `topRadius` above the cylinder, the base `bottomRadius`
        // below). RealityKit's generated primitives are centered on the entity
        // origin, so without this correction the collider sits low and the top of
        // the part (worst at the shoulders, where the radius gap is largest) has
        // no collider at all and never registers a paint hit. Offset every shape
        // to the mesh bounds center so the collider covers the whole surface.
        let b = bounds(for: part)
        let center = (b.min + b.max) / 2
        let base: ShapeResource
        switch part {
        case .head:
            base = .generateSphere(radius: s.topRadius)
        case .neck, .upperArm_L, .upperArm_R, .forearm_L, .forearm_R, .thigh_L, .thigh_R, .shin_L, .shin_R:
            // Capsule matches the organic mesh surface so raycasts land at the
            // correct curved position rather than on a flat box face. This fixes
            // UV distortion at seams and near silhouette edges.
            let r = max(s.topRadius, s.bottomRadius)
            let tipToTip = s.cylHeight + s.topRadius + s.bottomRadius
            base = .generateCapsule(height: tipToTip, radius: r)
        case .torso:
            base = .generateBox(width: b.max.x - b.min.x,
                                height: b.max.y - b.min.y,
                                depth: b.max.z - b.min.z)
        }
        return base.offsetBy(translation: center)
    }

    // MARK: - Bounds (drives UV projection in PaintSystem.computeUV)

    public static func bounds(for part: BodyPart) -> (min: SIMD3<Float>, max: SIMD3<Float>) {
        let s = shape(for: part)
        let halfH = s.cylHeight / 2
        let maxRX = max(s.topRadius, s.bottomRadius) * s.scaleX
        let maxRZ = max(s.topRadius, s.bottomRadius) * s.scaleZ
        let minY = -(halfH + s.bottomRadius)
        let maxY = halfH + s.topRadius
        return ([-maxRX, minY, -maxRZ], [maxRX, maxY, maxRZ])
    }

    public static func defaultMaterial() -> PhysicallyBasedMaterial {
        var material = PhysicallyBasedMaterial()
        #if canImport(UIKit)
        material.baseColor = PhysicallyBasedMaterial.BaseColor(
            tint: UIColor(white: 0.97, alpha: 1.0)
        )
        #endif
        material.roughness = 0.6
        material.metallic = 0.0
        return material
    }

    // MARK: - Layout
    //
    // Centers are tuned so adjacent parts overlap and blend into one body:
    // head sinks into the shoulders, arms tuck against the torso, hips plug the legs in.
    public static func bodyPartOffset(_ part: BodyPart) -> SIMD3<Float> {
        switch part {
        case .head:       return [0, 1.63, 0]
        case .neck:       return [0, 1.475, 0]
        case .torso:      return [0, 1.06, 0]
        case .upperArm_L: return [-0.205, 1.228, 0]
        case .upperArm_R: return [0.205, 1.228, 0]
        case .forearm_L:  return [-0.205, 1.008, 0]
        case .forearm_R:  return [0.205, 1.008, 0]
        case .thigh_L:    return [-0.09, 0.676, 0]
        case .thigh_R:    return [0.09, 0.676, 0]
        case .shin_L:     return [-0.09, 0.396, 0]
        case .shin_R:     return [0.09, 0.396, 0]
        }
    }
}
