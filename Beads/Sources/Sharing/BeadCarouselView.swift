import SwiftUI

/// A rotating elliptical bead wheel, not a linear strip: beads sit on an
/// ellipse, the bottom position is "nearest" (largest, sharpest), the top is
/// "farthest" (smallest, blurriest) — approximating a bracelet loop viewed
/// at an angle, the way real hand-strung beads actually sit when you look
/// down at them. Drag left/right to spin; it loops forever (angle wraps at
/// 360°, so there's no start or end to hit), and a full turn ticks
/// `completedSpins`.
struct BeadCarouselView: View {
    let tier: BeadTier
    let beyondIntensity: Double
    let cycleProgress: Int

    private let ringCapacity = BeadRingView.ringCapacity
    private let maxItemSize: CGFloat = 132
    private let minItemSize: CGFloat = 46

    @State private var rotationDegrees: Double
    @State private var dragStartRotation: Double = 0
    @State private var completedSpins: Int = 0

    init(tier: BeadTier, beyondIntensity: Double, cycleProgress: Int) {
        self.tier = tier
        self.beyondIntensity = beyondIntensity
        self.cycleProgress = cycleProgress
        // Land the most recently reached bead at the bottom (nearest) position
        // on first appearance, matching what the old scroll-to-current did.
        let ringCapacity = BeadRingView.ringCapacity
        let targetIndex = max(0, min(cycleProgress, ringCapacity - 1))
        let baseAngle = Double(targetIndex) / Double(ringCapacity) * 360
        _rotationDegrees = State(initialValue: 90 - baseAngle)
    }

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                let ellipseRadiusX = min(geo.size.width * 0.38, maxItemSize * 1.15)
                let ellipseRadiusY = maxItemSize * 0.4

                ZStack {
                    ForEach(0..<ringCapacity, id: \.self) { index in
                        beadView(index: index, center: center, radiusX: ellipseRadiusX, radiusY: ellipseRadiusY)
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            rotationDegrees = dragStartRotation + Double(value.translation.width) * 0.7
                            updateSpinCount()
                        }
                        .onEnded { _ in
                            dragStartRotation = rotationDegrees
                        }
                )
            }
            .frame(height: maxItemSize + maxItemSize * 0.4 * 2 + 12)

            Text("\(abs(completedSpins)) spins")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func angleDegrees(for index: Int) -> Double {
        let baseAngle = Double(index) / Double(ringCapacity) * 360
        return baseAngle + rotationDegrees
    }

    private func beadView(index: Int, center: CGPoint, radiusX: CGFloat, radiusY: CGFloat) -> some View {
        let degrees = angleDegrees(for: index)
        let radians = degrees * .pi / 180
        // Screen space: sin = +1 at the bottom of the ellipse (nearest), -1 at the top (farthest).
        let depth = sin(radians)
        let nearness = (depth + 1) / 2 // 0 = far, 1 = near

        let size = minItemSize + (maxItemSize - minItemSize) * nearness
        let blur = (1 - nearness) * 4.5
        let opacity = 0.45 + nearness * 0.55

        let x = center.x + cos(radians) * radiusX
        let y = center.y + depth * radiusY

        return BeadMaterialView(tier: tier, beyondIntensity: beyondIntensity, reached: index < cycleProgress, size: size)
            .rotationEffect(BeadStrandJitter.rotation(for: index))
            .blur(radius: blur)
            .opacity(opacity)
            .position(x: x, y: y)
            .zIndex(depth)
    }

    private func updateSpinCount() {
        let spins = Int(rotationDegrees / 360)
        if spins != completedSpins {
            completedSpins = spins
            Haptics.lightTap()
        }
    }
}

#Preview {
    BeadCarouselView(tier: BeadTierLibrary.loadTiers()[3], beyondIntensity: 0, cycleProgress: 5)
        .background(Color.black)
}
