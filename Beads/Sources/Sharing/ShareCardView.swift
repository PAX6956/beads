import SwiftUI

struct ShareCardView: View {
    let text: String
    let template: ShareCardTemplate
    // Pro perk: a user-picked photo replaces the template gradient entirely.
    // Rather than sampling per-region brightness to pick a "compatible" text
    // color, a fixed top/bottom vignette guarantees contrast for any photo —
    // the same approach Stories' own text tool uses — so text color there is
    // always white, no per-photo analysis needed.
    var customBackground: UIImage? = nil
    var growthValue: Double = 0
    var cycleProgress: Int = 0
    // `size` is the card's width; height follows a 9:16 portrait ratio so the
    // exported image fills a Stories/Reels-style full-screen reshare instead
    // of getting letterboxed the way the original 1:1 square did — that's
    // the single biggest lever for how far a quote card actually travels.
    var size: CGFloat = 360

    private var height: CGFloat { size * 16.0 / 9.0 }

    private var textColor: Color {
        customBackground != nil ? .white : template.textColor
    }

    private var tierInfo: (tier: BeadTier, beyondIntensity: Double)? {
        BeadTierLibrary.currentTier(growthValue: growthValue, tiers: BeadTierLibrary.loadTiers())
    }

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: size * 0.06) {
                Spacer(minLength: size * 0.16)

                if let tierInfo {
                    BeadMaterialView(tier: tierInfo.tier, beyondIntensity: tierInfo.beyondIntensity, reached: true, size: size * 0.36)

                    VStack(spacing: size * 0.01) {
                        Text(tierInfo.tier.name)
                            .font(.system(size: size * 0.032, design: .serif).weight(.semibold))
                            .foregroundStyle(textColor.opacity(0.85))
                        Text("\(Int(growthValue)) growth days")
                            .font(.system(size: size * 0.026))
                            .foregroundStyle(textColor.opacity(0.6))
                    }
                }

                Spacer(minLength: size * 0.08)

                // Fixed Dynamic Type styles (.title, .callout, .caption) stay
                // the same absolute point size no matter how big the card is,
                // so text that looked right on the small in-app preview went
                // nearly illegible at the real 1080pt export — every label
                // here needs to scale with `size` so preview and export match.
                Text(text)
                    .font(.system(size: size * 0.052, design: .serif).weight(.medium))
                    .foregroundStyle(textColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, size * 0.11)

                Spacer(minLength: size * 0.16)

                HStack(spacing: 6) {
                    Circle()
                        .fill(textColor.opacity(0.6))
                        .frame(width: 6, height: 6)
                    Text("Beads")
                        .font(.system(size: size * 0.022).weight(.semibold))
                        .foregroundStyle(textColor.opacity(0.7))
                }
                .padding(.bottom, size * 0.08)
            }
        }
        .frame(width: size, height: height)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.06))
    }

    @ViewBuilder
    private var backgroundLayer: some View {
        if let customBackground {
            ZStack {
                Image(uiImage: customBackground)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: height)
                    .clipped()

                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .black.opacity(0.55), location: 0),
                        .init(color: .black.opacity(0.05), location: 0.3),
                        .init(color: .black.opacity(0.05), location: 0.7),
                        .init(color: .black.opacity(0.6), location: 1)
                    ]),
                    startPoint: .top, endPoint: .bottom
                )
            }
        } else {
            template.background
        }
    }
}

@MainActor
enum ShareCardRenderer {
    static let exportWidth: CGFloat = 1080

    static func renderImage(text: String, template: ShareCardTemplate, customBackground: UIImage? = nil, growthValue: Double = 0, cycleProgress: Int = 0) -> UIImage? {
        let view = ShareCardView(text: text, template: template, customBackground: customBackground, growthValue: growthValue, cycleProgress: cycleProgress, size: exportWidth)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        return renderer.uiImage
    }
}

#Preview {
    ShareCardView(text: "Simplicity is the return to the root.", template: .sunsetGradient, growthValue: 120, cycleProgress: 6)
}
