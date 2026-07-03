import XCTest
import simd
@testable import DicyaninHumanoidMesh

final class DicyaninHumanoidMeshTests: XCTestCase {

    func testAllPartsHaveBounds() {
        for part in BodyPart.allCases {
            let b = HumanoidMesh.bounds(for: part)
            XCTAssertLessThan(b.min.y, b.max.y, "\(part) bounds should be non-degenerate")
        }
    }

    func testAllPartsGenerateMesh() {
        for part in BodyPart.allCases {
            _ = HumanoidMesh.generateBodyPart(part)
        }
    }

    func testPosePresetInterpolationEndpoints() {
        let t = PoseTransition(from: .aPose, to: .tPose, progress: 0)
        XCTAssertEqual(t.interpolatedAngles()[.upperArm_L], PosePreset.aPose.jointAngles[.upperArm_L], accuracy: 1e-6)

        let t1 = PoseTransition(from: .aPose, to: .tPose, progress: 1)
        XCTAssertEqual(t1.interpolatedAngles()[.upperArm_L], PosePreset.tPose.jointAngles[.upperArm_L], accuracy: 1e-6)
    }

    func testRotationAxes() {
        XCTAssertEqual(HumanoidEntity.rotationAxis(for: .thigh_L), SIMD3<Float>(1, 0, 0))
        XCTAssertEqual(HumanoidEntity.rotationAxis(for: .upperArm_R), SIMD3<Float>(0, 0, 1))
    }
}
