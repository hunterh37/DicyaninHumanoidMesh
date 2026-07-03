import RealityKit
import CoreGraphics

#if canImport(UIKit)
import UIKit
#endif

/// Per-body-part paint metadata attached to each mesh entity. Painting systems in
/// the host app read and mutate this to track undo state and texture identity.
public struct PaintComponent: Component, Codable {
    public var textureHash: Int = 0
    public var undoStack: [Int] = []

    public init() {}
}

/// Blank base surface used to seed each body part's paintable texture.
public enum PaintTexture {

    public static let textureSize = CGSize(width: 256, height: 256)

    public static func createBlankCGImage() -> CGImage {
        let size = textureSize
        #if canImport(UIKit)
        let color = UIColor(white: 0.65, alpha: 1.0)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            color.setFill()
            ctx.fill(.init(origin: .zero, size: size))
        }
        return image.cgImage!
        #else
        let w = Int(size.width), h = Int(size.height)
        let gray = UInt8(166)
        var pixels = [UInt8](repeating: 255, count: w * h * 4)
        var i = 0
        while i < pixels.count {
            pixels[i] = gray; pixels[i + 1] = gray; pixels[i + 2] = gray; pixels[i + 3] = 255
            i += 4
        }
        let cs = CGColorSpaceCreateDeviceRGB()
        let ctx = CGContext(data: &pixels, width: w, height: h, bitsPerComponent: 8,
                            bytesPerRow: w * 4, space: cs,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        return ctx.makeImage()!
        #endif
    }

    public static func createBlankTexture() -> TextureResource? {
        try? TextureResource.generate(from: createBlankCGImage(), options: .init(semantic: .color))
    }
}
