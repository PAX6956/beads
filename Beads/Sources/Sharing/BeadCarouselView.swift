import SwiftUI

/// A rotating elliptical bead wheel, not a linear strip: beads sit on an
/// ellipse, the bottom position is "nearest" (largest, sharpest), the top is
/// "farthest" (smallest, blurriest) — approximating a bracelet loop viewed
/// at an angle, the way real hand-strung beads actually sit when you look
/// down at them. Drag left/right to spin; it loops forever (angle wraps at
/// 360°, so there's no start or end to hit). Every bead-step is a small
/// haptic "click," like real beads passing under a thumb, and (up to a daily
/// cap) nudges growthValue — handling the beads is meant to be its own small
/// moment of focus, not just a decoration.
struct BeadCarouselView: View {
    let tier: BeadTier
    let beyondIntensity: Double
    // Reports cumulative |rotation| after every change, so a parent (the
    // reveal-as-you-spin quote text on the Beads tab) can drive off the same
    // number the "N spins" label already uses, without owning any of this
    // view's drag/rotation state itself.
    var onDistanceChange: ((Double) -> Void)? = nil

    @EnvironmentObject private var store: PracticeStore

    // Purely a layout constant now (how many bead positions sit on the
    // ellipse) — every position always renders the same tier material, so
    // this no longer doubles as a progress capacity like it used to.
    private let beadPositionCount = 12
    private let maxItemSize: CGFloat = 106 // 80% of the original 132
    private let minItemSize: CGFloat = 46
    // The ellipse's own footprint is kept at the original 132 baseline —
    // only the beads themselves shrank to 106; the loop they sit on should
    // stay the size it was before that change.
    private let ellipseBaseSize: CGFloat = 132

    @State private var rotationDegrees: Double = 90
    @State private var dragStartRotation: Double = 90
    @State private var completedSpins: Int = 0
    @State private var lastBeadStep: Int
    // Tracks cumulative |rotation| traveled, not signed rotationDegrees, so
    // reversing direction never makes the visible spin count tick backward —
    // both directions of handling the beads should only ever add.
    @State private var totalDistanceTraveled: Double = 0
    @State private var lastRotationForDistance: Double = 90

    init(tier: BeadTier, beyondIntensity: Double, onDistanceChange: ((Double) -> Void)? = nil) {
        self.tier = tier
        self.beyondIntensity = beyondIntensity
        self.onDistanceChange = onDistanceChange
        _lastBeadStep = State(initialValue: Self.beadStep(for: 90, beadPositionCount: 12))
    }

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                let ellipseRadiusX = min(geo.size.width * 0.38, ellipseBaseSize * 1.15)
                let ellipseRadiusY = ellipseBaseSize * 0.4

                ZStack {
                    ForEach(0..<beadPositionCount, id: \.self) { index in
                        beadView(index: index, center: center, radiusX: ellipseRadiusX, radiusY: ellipseRadiusY)
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // Negated: at the bottom (nearest) position, increasing
                            // rotationDegrees moves that bead toward the left on
                            // screen, which felt backwards against a rightward drag.
                            // Flipping the sign makes the nearest bead follow the
                            // finger's direction instead of mirroring it.
                            rotationDegrees = dragStartRotation - Double(value.translation.width) * 0.7
                            handleRotationChange()
                        }
                        .onEnded { _ in
                            dragStartRotation = rotationDegrees
                        }
                )
            }
            .frame(height: ellipseBaseSize + ellipseBaseSize * 0.4 * 2 + 12)

            Text("\(completedSpins) spins")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func angleDegrees(for index: Int) -> Double {
        let baseAngle = Double(index) / Double(beadPositionCount) * 360
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

        // Far beads share the same angular spacing as near ones but render
        // much smaller, so a fixed horizontal radius left them looking
        // sparse/adrift near the top. Narrowing the ellipse as nearness drops
        // pulls the far beads inward — like railway tracks converging toward
        // a vanishing point — so they cluster instead of spreading thin. The
        // far-end floor (0.55) is unchanged from the original fix; the near
        // end is raised to 1.10 (10% wider than the original 1.0) since the
        // front row read as too cramped once the far end tightened.
        let effectiveRadiusX = radiusX * (0.55 + 0.55 * nearness)

        // Vertical travel was still using the full fixed radiusY for every
        // bead regardless of depth, so the far arc swept just as high/low as
        // the near one — a real perspective view would have the distant loop
        // shrink toward the vanishing point in *both* directions, not just
        // horizontally. Compressing radiusY the same way flattens the far
        // arc into a smaller, tighter curve near the top.
        let effectiveRadiusY = radiusY * (0.55 + 0.55 * nearness)

        let x = center.x + cos(radians) * effectiveRadiusX
        let y = center.y + depth * effectiveRadiusY

        // Depth is conveyed by size + blur only — fading opacity too caused
        // overlapping near beads to show a translucent "ghosting" double-
        // image where their circles crossed, since none of them ever quite
        // hit fully opaque. Fully opaque + correct zIndex is enough for the
        // front bead to cleanly occlude the ones behind it.
        return BeadMaterialView(tier: tier, beyondIntensity: beyondIntensity, size: size)
            .rotationEffect(BeadStrandJitter.rotation(for: index))
            .blur(radius: blur)
            .position(x: x, y: y)
            .zIndex(depth)
    }

    private static func beadStep(for rotation: Double, beadPositionCount: Int) -> Int {
        let degreesPerBead = 360.0 / Double(beadPositionCount)
        return Int((rotation / degreesPerBead).rounded())
    }

    private func handleRotationChange() {
        let step = Self.beadStep(for: rotationDegrees, beadPositionCount: beadPositionCount)
        if step != lastBeadStep {
            lastBeadStep = step
            Haptics.lightTap()
            store.recordSpinTick()
        }

        // Accumulate |Δrotation| rather than reading rotationDegrees directly —
        // a signed reading would tick the "spins" count back down whenever a
        // reversed drag crosses back over a multiple-of-360 boundary.
        totalDistanceTraveled += abs(rotationDegrees - lastRotationForDistance)
        lastRotationForDistance = rotationDegrees
        completedSpins = Int(totalDistanceTraveled / 360)
        onDistanceChange?(totalDistanceTraveled)
    }
}

#Preview {
    BeadCarouselView(tier: BeadTierLibrary.loadTiers()[3], beyondIntensity: 0)
        .environmentObject(PracticeStore())
        .background(Color.black)
}
