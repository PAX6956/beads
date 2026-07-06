import SwiftUI

struct ShareCardView: View {
    let text: String
    let template: ShareCardTemplate
    var size: CGFloat = 360

    var body: some View {
        ZStack {
            template.background
            VStack {
                Spacer()
                Text(text)
                    .font(.system(.title2, design: .serif).weight(.medium))
                    .foregroundStyle(template.textColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, size * 0.09)
                Spacer()
                HStack(spacing: 6) {
                    Circle()
                        .fill(template.textColor.opacity(0.6))
                        .frame(width: 6, height: 6)
                    Text("Beads")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(template.textColor.opacity(0.7))
                }
                .padding(.bottom, size * 0.06)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.06))
    }
}

@MainActor
enum ShareCardRenderer {
    static let exportSize: CGFloat = 1080

    static func renderImage(text: String, template: ShareCardTemplate) -> UIImage? {
        let view = ShareCardView(text: text, template: template, size: exportSize)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        return renderer.uiImage
    }
}

#Preview {
    ShareCardView(text: "Simplicity is the return to the root.", template: .sunsetGradient)
}
