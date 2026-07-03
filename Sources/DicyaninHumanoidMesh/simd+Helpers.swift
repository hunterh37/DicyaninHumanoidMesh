import simd

extension SIMD3 where Scalar == Float {
    public func clamped(to range: ClosedRange<Float>) -> SIMD3 {
        SIMD3(
            Swift.min(Swift.max(x, range.lowerBound), range.upperBound),
            Swift.min(Swift.max(y, range.lowerBound), range.upperBound),
            Swift.min(Swift.max(z, range.lowerBound), range.upperBound)
        )
    }

    public static func lerp(_ a: SIMD3, _ b: SIMD3, t: Float) -> SIMD3 {
        a + (b - a) * t
    }
}

extension simd_float4x4 {
    public var translation: SIMD3<Float> {
        SIMD3(columns.3.x, columns.3.y, columns.3.z)
    }
}

extension simd_quatf {
    public static let identity = simd_quatf(angle: 0, axis: [0, 1, 0])

    /// Extracts the rotation about the Y axis, used to sync humanoid facing
    /// direction over the network without sending a full quaternion.
    public var yawAngle: Float {
        let forward = act(SIMD3<Float>(0, 0, -1))
        return atan2(forward.x, -forward.z)
    }
}
