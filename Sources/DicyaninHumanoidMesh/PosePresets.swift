import Foundation
import simd

public enum BodyPart: String, CaseIterable, Sendable {
    case head, neck, torso
    case upperArm_L, upperArm_R
    case forearm_L, forearm_R
    case thigh_L, thigh_R
    case shin_L, shin_R
}

public struct JointAngles: Equatable, Sendable {
    public var angles: [BodyPart: Float]

    public init(angles: [BodyPart: Float] = [:]) {
        self.angles = angles
    }

    public subscript(_ part: BodyPart) -> Float {
        get { angles[part] ?? 0 }
        set { angles[part] = newValue }
    }
}

public enum PosePreset: CaseIterable, Sendable {
    case aPose
    case tPose
    case handsInPockets
    case sitting
    case floorCrossLegged
    case wallLean
    case crouch
    case dabbing
    case pointing
    case yogaTree
    case spreadEagle
    case layingDown
    case handsUp
    case curledBall
    case pressWall
    case funnyPose
    case secretPose
    // Emote reaction poses, one per EmoteKind. Deterministic so every peer
    // reproduces the same body language from the networked emote alone.
    case bigWave
    case heartHands
    case handOutreach
    case laughing
    case fireArms
    case shrug

    public var jointAngles: JointAngles {
        switch self {
        case .aPose:
            var j = JointAngles()
            j[.upperArm_L] = -.pi / 9
            j[.upperArm_R] = .pi / 9
            return j
        case .tPose:
            var j = JointAngles()
            j[.upperArm_L] = -.pi / 4
            j[.upperArm_R] = .pi / 4
            return j
        case .handsInPockets:
            var j = JointAngles()
            j[.upperArm_L] = -.pi / 6
            j[.upperArm_R] = .pi / 6
            return j
        case .sitting:
            var j = JointAngles()
            j[.thigh_L] = .pi / 2
            j[.thigh_R] = .pi / 2
            j[.shin_L] = -.pi / 2
            j[.shin_R] = -.pi / 2
            return j
        case .floorCrossLegged:
            var j = JointAngles()
            j[.thigh_L] = .pi / 3
            j[.thigh_R] = -.pi / 3
            return j
        case .wallLean:
            var j = JointAngles()
            j[.torso] = .pi / 12
            return j
        case .crouch:
            var j = JointAngles()
            j[.thigh_L] = .pi / 4
            j[.thigh_R] = .pi / 4
            j[.shin_L] = -.pi / 2
            j[.shin_R] = -.pi / 2
            j[.torso] = .pi / 6
            return j
        case .dabbing:
            var j = JointAngles()
            j[.upperArm_L] = -.pi / 2
            j[.upperArm_R] = .pi / 4
            j[.forearm_L] = -.pi / 3
            j[.forearm_R] = -.pi / 4
            j[.torso] = .pi / 8
            return j
        case .pointing:
            var j = JointAngles()
            j[.upperArm_R] = .pi / 3
            return j
        case .yogaTree:
            var j = JointAngles()
            j[.thigh_R] = .pi / 2
            j[.upperArm_L] = -.pi / 3
            j[.upperArm_R] = .pi / 3
            return j
        case .spreadEagle:
            var j = JointAngles()
            j[.upperArm_L] = -.pi / 2
            j[.upperArm_R] = .pi / 2
            j[.thigh_L] = -.pi / 4
            j[.thigh_R] = .pi / 4
            return j
        case .layingDown:
            var j = JointAngles()
            j[.torso] = .pi / 2
            j[.thigh_L] = -.pi / 4
            j[.thigh_R] = -.pi / 4
            return j
        case .handsUp:
            var j = JointAngles()
            j[.upperArm_L] = -.pi * 3 / 4
            j[.upperArm_R] = .pi * 3 / 4
            return j
        case .curledBall:
            var j = JointAngles()
            j[.torso] = .pi / 3
            j[.thigh_L] = .pi / 2
            j[.thigh_R] = .pi / 2
            j[.upperArm_L] = -.pi / 6
            j[.upperArm_R] = .pi / 6
            return j
        case .pressWall:
            var j = JointAngles()
            j[.torso] = -.pi / 3
            j[.upperArm_L] = -.pi / 6
            j[.upperArm_R] = .pi / 6
            return j
        case .funnyPose:
            var j = JointAngles()
            j[.upperArm_L] = -.pi / 2
            j[.upperArm_R] = .pi / 8
            j[.thigh_L] = .pi / 6
            j[.torso] = -.pi / 8
            return j
        case .secretPose:
            var j = JointAngles()
            j[.upperArm_L] = -.pi / 3
            j[.upperArm_R] = -.pi / 3
            j[.thigh_L] = .pi / 4
            j[.thigh_R] = -.pi / 4
            j[.torso] = .pi / 4
            return j
        case .bigWave:
            // Right arm raised overhead, forearm cocked to wave.
            var j = JointAngles()
            j[.upperArm_R] = .pi * 3 / 4
            j[.forearm_R] = -.pi / 6
            j[.upperArm_L] = .pi / 12
            j[.torso] = -.pi / 16
            return j
        case .heartHands:
            // Both hands drawn up to the chest.
            var j = JointAngles()
            j[.upperArm_L] = -.pi / 3
            j[.upperArm_R] = .pi / 3
            j[.forearm_L] = -.pi / 2
            j[.forearm_R] = -.pi / 2
            return j
        case .handOutreach:
            // Right arm reaches out and forward, offering a thumbs-up.
            var j = JointAngles()
            j[.upperArm_R] = .pi / 2
            j[.forearm_R] = -.pi / 2
            j[.torso] = -.pi / 16
            return j
        case .laughing:
            // Lean back, arms loose at the sides.
            var j = JointAngles()
            j[.torso] = -.pi / 7
            j[.upperArm_L] = -.pi / 7
            j[.upperArm_R] = .pi / 7
            j[.forearm_L] = -.pi / 3
            j[.forearm_R] = -.pi / 3
            return j
        case .fireArms:
            // Both arms thrown up in celebration.
            var j = JointAngles()
            j[.upperArm_L] = -.pi * 3 / 4
            j[.upperArm_R] = .pi * 3 / 4
            j[.forearm_L] = -.pi / 4
            j[.forearm_R] = -.pi / 4
            return j
        case .shrug:
            // Palms-up shrug for a questioning reaction.
            var j = JointAngles()
            j[.upperArm_L] = -.pi / 5
            j[.upperArm_R] = .pi / 5
            j[.forearm_L] = -.pi / 2
            j[.forearm_R] = -.pi / 2
            return j
        }
    }

    public var displayName: String {
        switch self {
        case .aPose: return String(localized: "A-Pose")
        case .tPose: return String(localized: "T-Pose")
        case .handsInPockets: return String(localized: "Hands in Pockets")
        case .sitting: return String(localized: "Sitting")
        case .floorCrossLegged: return String(localized: "Cross-Legged")
        case .wallLean: return String(localized: "Wall Lean")
        case .crouch: return String(localized: "Crouch")
        case .dabbing: return String(localized: "Dabbing")
        case .pointing: return String(localized: "Pointing")
        case .yogaTree: return String(localized: "Yoga Tree")
        case .spreadEagle: return String(localized: "Spread Eagle")
        case .layingDown: return String(localized: "Lay Flat")
        case .handsUp: return String(localized: "Hands Up")
        case .curledBall: return String(localized: "Curled Ball")
        case .pressWall: return String(localized: "Press Wall")
        case .funnyPose: return String(localized: "Funny")
        case .secretPose: return String(localized: "???")
        case .bigWave: return String(localized: "Big Wave")
        case .heartHands: return String(localized: "Heart Hands")
        case .handOutreach: return String(localized: "Hand Outreach")
        case .laughing: return String(localized: "Laughing")
        case .fireArms: return String(localized: "Fire Arms")
        case .shrug: return String(localized: "Shrug")
        }
    }
}

public struct PoseTransition: Sendable {
    public var from: PosePreset
    public var to: PosePreset
    public var progress: Float

    public init(from: PosePreset, to: PosePreset, progress: Float) {
        self.from = from
        self.to = to
        self.progress = progress
    }

    public func interpolatedAngles() -> JointAngles {
        let fromAngles = from.jointAngles
        let toAngles = to.jointAngles
        var result = JointAngles()
        for part in BodyPart.allCases {
            let fromVal = fromAngles[part]
            let toVal = toAngles[part]
            result[part] = fromVal + (toVal - fromVal) * progress
        }
        return result
    }
}
