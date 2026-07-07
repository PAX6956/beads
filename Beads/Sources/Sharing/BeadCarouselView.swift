import SwiftUI

/// A coverflow-style strand: the bead nearest the center of the visible strip
/// is large and sharp, beads further out shrink, blur, and fade — a cheap
/// (pure SwiftUI, no SceneKit) approximation of depth that reads as "a string
/// curving away from you" rather than a flat row of dots. Real texture
/// assets (once they exist) will read far better in this large, focused
/// treatment than they ever could as a 12px ring dot.
struct BeadCarouselView: View {
    let tier: BeadTier
    let beyondIntensity: Double
    let cycleProgress: Int

    private let itemSize: CGFloat = 92
    private let spacing: CGFloat = 30
    private let ringCapacity = BeadRingView.ringCapacity

    var body: some View {
        GeometryReader { outerGeo in
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: spacing) {
                        ForEach(0..<ringCapacity, id: \.self) { index in
                            BeadMaterialView(
                                tier: tier,
                                beyondIntensity: beyondIntensity,
                                reached: index < cycleProgress,
                                size: itemSize
                            )
                            .id(index)
                            .modifier(DepthEffect(containerWidth: outerGeo.size.width))
                        }
                    }
                    .padding(.horizontal, max(0, (outerGeo.size.width - itemSize) / 2))
                    .coordinateSpace(name: DepthEffect.coordinateSpaceName)
                }
                .onAppear {
                    let target = max(0, min(cycleProgress, ringCapacity - 1))
                    DispatchQueue.main.async {
                        proxy.scrollTo(target, anchor: .center)
                    }
                }
            }
        }
        .frame(height: itemSize * 1.7)
    }
}

private struct DepthEffect: ViewModifier {
    static let coordinateSpaceName = "beadCarousel"
    let containerWidth: CGFloat

    @State private var scale: CGFloat = 0.6
    @State private var blur: CGFloat = 3
    @State private var fade: Double = 0.6

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .blur(radius: blur)
            .opacity(fade)
            .background(
                GeometryReader { geo in
                    Color.clear.onAppear { update(with: geo) }.onChange(of: geo.frame(in: .named(Self.coordinateSpaceName)).midX) { _ in
                        update(with: geo)
                    }
                }
            )
    }

    private func update(with geo: GeometryProxy) {
        let midX = geo.frame(in: .named(Self.coordinateSpaceName)).midX
        let center = containerWidth / 2
        let distance = abs(midX - center)
        let normalized = min(1, distance / max(center, 1))
        scale = 1 - normalized * 0.45
        blur = normalized * 3
        fade = 1 - normalized * 0.55
    }
}

#Preview {
    BeadCarouselView(tier: BeadTierLibrary.loadTiers()[3], beyondIntensity: 0, cycleProgress: 5)
        .background(Color.black)
}
