import UIKit
import CoreImage

/// Computes how dark an overlay needs to be, per region of a user-picked
/// photo, so white text stays legible on top of it — replaces a fixed
/// vignette that darkened the top/bottom edges by a constant amount
/// regardless of the photo, while leaving the middle (where the quote text
/// actually sits) barely touched.
enum ImageContrast {
    /// Target effective luminance behind text once darkened, and the opacity
    /// range we're willing to darken within (never fully clear — some
    /// consistency across photos — and never fully black, which would just
    /// hide the photo the user picked).
    private static let targetLuminance = 0.32
    private static let minOpacity = 0.22
    private static let maxOpacity = 0.88

    struct RegionOpacities {
        let top: Double
        let middle: Double
        let bottom: Double
    }

    /// `image` is sampled in three horizontal bands (top/middle/bottom
    /// thirds) matching where the tier info, quote, and footer roughly land
    /// in `ShareCardView`. This is an approximation of the on-screen crop
    /// (scaledToFill can crop the source differently), but for a "is this
    /// region generally bright or dark" read it's close enough.
    static func regionOpacities(for image: UIImage) -> RegionOpacities {
        RegionOpacities(
            top: opacity(forLuminance: averageLuminance(of: image, verticalRange: 0..<0.3)),
            middle: opacity(forLuminance: averageLuminance(of: image, verticalRange: 0.3..<0.7)),
            bottom: opacity(forLuminance: averageLuminance(of: image, verticalRange: 0.7..<1.0))
        )
    }

    private static func opacity(forLuminance luminance: Double) -> Double {
        guard luminance > 0.001 else { return minOpacity }
        let needed = 1 - targetLuminance / luminance
        return min(maxOpacity, max(minOpacity, needed))
    }

    private static func averageLuminance(of image: UIImage, verticalRange: Range<Double>) -> Double {
        guard let ciImage = CIImage(image: image) else { return 0.5 }
        let extent = ciImage.extent
        // CIImage's origin is bottom-left; UIKit/SwiftUI's top-down band
        // needs flipping onto CoreImage's coordinate space.
        let cropRect = CGRect(
            x: extent.minX,
            y: extent.minY + (1 - verticalRange.upperBound) * extent.height,
            width: extent.width,
            height: (verticalRange.upperBound - verticalRange.lowerBound) * extent.height
        ).intersection(extent)
        guard !cropRect.isEmpty else { return 0.5 }

        guard let filter = CIFilter(name: "CIAreaAverage") else { return 0.5 }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgRect: cropRect), forKey: kCIInputExtentKey)
        guard let outputImage = filter.outputImage else { return 0.5 }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: NSNull()])
        context.render(
            outputImage, toBitmap: &bitmap, rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8, colorSpace: nil
        )

        let r = Double(bitmap[0]) / 255.0
        let g = Double(bitmap[1]) / 255.0
        let b = Double(bitmap[2]) / 255.0
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }
}
