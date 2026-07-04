import Foundation
import simd

/// Procedural locomotion for the humanoid skeleton: a phase-driven walk cycle
/// and a subtle idle motion, blended by a 0...1 walk weight.
///
/// Everything here is a pure function of (walkPhase, idleClock, walkBlend), so
/// any two peers that feed the same inputs compute identical joint angles.
/// Driving walkPhase from distance traveled (see `advancePhase`) keeps remote
/// avatars in step with their motion, which keeps multiplayer views in sync
/// without sending any extra animation state over the network.
public enum GaitAnimation {

    // MARK: - Tuning

    /// Stride cycles per meter traveled. One full cycle is both steps.
    public static let strideCyclesPerMeter: Float = 0.9

    /// Speed (m/s) at which the walk cycle is fully blended in.
    public static let fullWalkSpeed: Float = 0.5

    /// Speed (m/s) below which motion is treated as standing still.
    public static let idleSpeedThreshold: Float = 0.05

    /// Max thigh swing amplitude (radians) at full walk.
    public static let thighSwing: Float = 0.55

    /// Max knee flex (radians) during the swing phase of a step.
    public static let kneeFlex: Float = 0.85

    /// Side-to-side torso weight-shift roll at full walk (radians).
    public static let torsoSway: Float = 0.05

    /// Frontal-plane arm sway amplitude at full walk (radians).
    public static let armSway: Float = 0.12

    // MARK: - Phase driving

    /// Advances a walk phase by distance traveled. Deterministic in position,
    /// so all peers replaying the same motion stay in step.
    public static func advancePhase(_ phase: Float, speed: Float, dt: Float) -> Float {
        let next = phase + speed * dt * strideCyclesPerMeter * 2 * .pi
        return next.truncatingRemainder(dividingBy: 2 * .pi)
    }

    /// Smoothly retargets the walk blend toward the weight implied by speed.
    public static func updateBlend(_ blend: Float, speed: Float, dt: Float) -> Float {
        let target: Float = speed <= idleSpeedThreshold
            ? 0
            : min(speed / fullWalkSpeed, 1)
        let t = 1 - exp(-10 * dt)
        return blend + (target - blend) * t
    }

    // MARK: - Pose sampling

    /// Joint angles for the current locomotion state. Includes the A-pose arm
    /// rest offsets so the result can be applied directly to the skeleton.
    public static func angles(walkPhase: Float, idleClock: Float, walkBlend: Float) -> JointAngles {
        let idle = idleAngles(clock: idleClock)
        guard walkBlend > 0.001 else { return idle }
        let walk = walkAngles(phase: walkPhase)
        var result = JointAngles()
        for part in BodyPart.allCases {
            result[part] = idle[part] + (walk[part] - idle[part]) * walkBlend
        }
        return result
    }

    /// One full walk cycle: legs alternate in the sagittal plane with knee
    /// flex during swing, torso rolls with the weight shift, arms sway.
    public static func walkAngles(phase: Float) -> JointAngles {
        var j = JointAngles()

        let swingL = sin(phase)
        let swingR = sin(phase + .pi)
        j[.thigh_L] = swingL * thighSwing
        j[.thigh_R] = swingR * thighSwing

        // Knee flexes while its leg swings forward, straightens in stance.
        j[.shin_L] = -max(0, sin(phase + .pi * 0.35)) * kneeFlex
        j[.shin_R] = -max(0, sin(phase + .pi * 1.35)) * kneeFlex

        // Weight shifts side to side once per step.
        j[.torso] = sin(phase) * torsoSway

        // Arms counter the legs with a light frontal sway around the A-pose.
        j[.upperArm_L] = -.pi / 9 + swingR * armSway
        j[.upperArm_R] = .pi / 9 + swingL * armSway
        j[.forearm_L] = -max(0, swingR) * 0.25
        j[.forearm_R] = -max(0, swingL) * 0.25

        return j
    }

    /// Subtle standing motion: slow breathing sway in the torso and arms and
    /// a faint weight shift, all low-frequency so it reads as alive, not busy.
    public static func idleAngles(clock: Float) -> JointAngles {
        var j = JointAngles()
        let breathe = sin(clock * 1.6)
        let shift = sin(clock * 0.35)

        j[.torso] = shift * 0.02
        j[.upperArm_L] = -.pi / 9 - breathe * 0.02 - shift * 0.01
        j[.upperArm_R] = .pi / 9 + breathe * 0.02 + shift * 0.01
        j[.forearm_L] = -breathe * 0.015
        j[.forearm_R] = -breathe * 0.015
        j[.thigh_L] = shift * 0.008
        j[.thigh_R] = -shift * 0.008
        return j
    }
}
