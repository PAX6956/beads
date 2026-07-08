import SwiftUI

/// A single-line marquee of today's quote + micro-action, sitting above the
/// bead wheel — driven by the wheel's cumulative spin distance (the same
/// always-increasing number behind its "N spins" counter), so text always
/// flows right-to-left into view no matter which way the wheel is dragged.
/// Ties the physical act of handling the beads to reading through the day's
/// content, the way counting beads while reciting works in the practice
/// this app is modeled on — you have to keep spinning to read the whole
/// thing, rather than it all being visible (and skippable) at once.
struct QuoteTickerView: View {
    let item: ContentItem
    let spinDistance: Double

    // A gap of plain spaces between the loop's end and its repeat, so the
    // seam doesn't read as two sentences mashed together.
    private var tickerText: String {
        "\(item.localizedQuote)      \(item.microAction)      "
    }

    @State private var singleWidth: CGFloat = 0
    // Fed into `.id()` below to force a full reset (including re-measuring
    // singleWidth, which genuinely changes width between languages) when
    // Quote Language changes in Settings — see TodayView for why a plain
    // declared-but-unread @AppStorage property wasn't enough on its own.
    @AppStorage(QuoteLanguagePreference.storageKey) private var quoteLanguageTrigger: String = QuoteLanguagePreference.system.rawValue

    var body: some View {
        GeometryReader { geo in
            let offset = singleWidth > 0 ? -spinDistance.truncatingRemainder(dividingBy: singleWidth) : 0
            // Enough repeated copies to cover the visible width plus one
            // full loop, so there's never a gap while wrapping around —
            // needed for short combined text on a wide screen.
            let copies = singleWidth > 0 ? Int(ceil(geo.size.width / singleWidth)) + 2 : 2

            HStack(spacing: 0) {
                ForEach(0..<copies, id: \.self) { _ in
                    Text(tickerText)
                        .lineLimit(1)
                        .fixedSize()
                        .background(widthReader)
                }
            }
            .offset(x: offset)
        }
        .frame(height: 24)
        .clipped()
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.secondary)
        // Text butting straight up against the screen edges read as visually
        // abrupt — a fade mask at both ends makes it feel like it's drifting
        // in and out rather than getting cut off.
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: 0.1),
                    .init(color: .black, location: 0.9),
                    .init(color: .clear, location: 1)
                ],
                startPoint: .leading, endPoint: .trailing
            )
        )
        .id(quoteLanguageTrigger)
    }

    private var widthReader: some View {
        GeometryReader { proxy in
            Color.clear.onAppear {
                if singleWidth == 0 { singleWidth = proxy.size.width }
            }
        }
    }
}

#Preview {
    QuoteTickerView(item: ContentLibrary.loadSeed().first!, spinDistance: 300)
        .padding()
}
