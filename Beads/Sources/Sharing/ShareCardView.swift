import SwiftUI

struct ShareCardView: View {
    let text: String
    let template: ShareCardTemplate
    // Pro perk: a user-picked photo replaces the template gradient entirely.
    // Text color is always white against it; legibility instead comes from
    // `customBackgroundOpacities` — a per-region darkening amount actually
    // measured from the photo (see ImageContrast) rather than a fixed guess.
    var customBackground: UIImage? = nil
    // Computed once by the caller (ImageContrast.regionOpacities) and passed
    // in, not recomputed here — this view's body can re-evaluate often (live
    // preview), and CIAreaAverage sampling isn't free.
    var customBackgroundOpacities: ImageContrast.RegionOpacities? = nil
    var growthValue: Double = 0
    var cycleProgress: Int = 0
    // `size` is the card's width; height follows a 9:16 portrait ratio so the
    // exported image fills a Stories/Reels-style full-screen reshare instead
    // of getting letterboxed the way the original 1:1 square did — that's
    // the single biggest lever for how far a quote card actually travels.
    var size: CGFloat = 360

    // Fed into `.id()` below to force a re-render when Quote Language
    // changes in Settings while this card is on screen; see TodayView for
    // why a declared-but-unread @AppStorage property alone wasn't enough.
    @AppStorage(QuoteLanguagePreference.storageKey) private var quoteLanguageTrigger: String = QuoteLanguagePreference.system.rawValue

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
                        Text(tierInfo.tier.localizedName)
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

                // Reverted the vector "BeadsMark" + Pro-purple experiment
                // after user testing found it visually unconvincing — back
                // to the plain dot + wordmark, sized up 150% (9pt dot,
                // 0.033 vs. the original 0.022 font scale) per follow-up.
                // Spacing pulled in 20% (9 -> 7.2) per further feedback.
                VStack(spacing: size * 0.012) {
                    HStack(spacing: 7.2) {
                        Circle()
                            .fill(textColor.opacity(0.6))
                            .frame(width: 9, height: 9)
                        Text("Beads")
                            .font(.system(size: size * 0.033).weight(.semibold))
                            .foregroundStyle(textColor.opacity(0.7))
                    }
                    // The slogan travels with every shared card, so this is
                    // the highest-leverage place for it — kept subtler than
                    // the wordmark itself, a signature rather than a headline.
                    Text("Hold on to it — Beads holds on to you.")
                        .font(.system(size: size * 0.02))
                        .foregroundStyle(textColor.opacity(0.55))
                }
                .padding(.bottom, size * 0.08)
            }
        }
        .frame(width: size, height: height)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.06))
        .id(quoteLanguageTrigger)
    }

    @ViewBuilder
    private var backgroundLayer: some View {
        if let customBackground {
            let opacities = customBackgroundOpacities ?? ImageContrast.RegionOpacities(top: 0.5, middle: 0.5, bottom: 0.5)
            ZStack {
                Image(uiImage: customBackground)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: height)
                    .clipped()

                // Three bands, not a top/bottom vignette with a clear middle —
                // the quote (the main thing being read) sits roughly in that
                // middle band, so it needs real coverage too, not just the
                // edges where the smaller tier/footer text lives.
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .black.opacity(opacities.top), location: 0),
                        .init(color: .black.opacity(opacities.middle), location: 0.5),
                        .init(color: .black.opacity(opacities.bottom), location: 1)
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

    static func renderImage(text: String, template: ShareCardTemplate, customBackground: UIImage? = nil, customBackgroundOpacities: ImageContrast.RegionOpacities? = nil, growthValue: Double = 0, cycleProgress: Int = 0) -> UIImage? {
        let view = ShareCardView(text: text, template: template, customBackground: customBackground, customBackgroundOpacities: customBackgroundOpacities, growthValue: growthValue, cycleProgress: cycleProgress, size: exportWidth)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        return renderer.uiImage
    }
}

#Preview {
    ShareCardView(text: "Simplicity is the return to the root.", template: .sunsetGradient, growthValue: 120, cycleProgress: 6)
}
