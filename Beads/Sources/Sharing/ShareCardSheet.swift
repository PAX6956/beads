import SwiftUI

struct ShareCardSheet: View {
    let text: String

    @EnvironmentObject private var store: PracticeStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTemplate: ShareCardTemplate = .inkWash
    @State private var shareURL: URL?
    @State private var previewImage: Image?
    @State private var showGrowthPulse = false
    @State private var leveledUp = false

    private var cycleProgress: Int { store.beadCount % BeadRingView.ringCapacity }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                ShareCardView(text: text, template: selectedTemplate, growthValue: store.growthValue, cycleProgress: cycleProgress)
                    .shadow(radius: 12, y: 6)
                    .padding(.top, 16)

                templatePicker

                shareButton

                Spacer()
            }
            .navigationTitle("Ripple Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task(id: selectedTemplate) {
                renderToTempFile()
            }
            .growthPulse(isPresented: $showGrowthPulse, tier: store.currentTierInfo?.tier, beyondIntensity: store.currentTierInfo?.beyondIntensity ?? 0, leveledUp: leveledUp)
        }
    }

    @ViewBuilder
    private var shareButton: some View {
        if let shareURL {
            ShareLink(item: shareURL, preview: SharePreview(text, image: previewImage ?? Image(systemName: "photo"))) {
                Label("Share", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
            .simultaneousGesture(TapGesture().onEnded { recordShareGrowth() })
        } else {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding()
        }
    }

    private func recordShareGrowth() {
        let previousTier = store.currentTierInfo?.tier.order
        store.recordShare()
        leveledUp = previousTier != store.currentTierInfo?.tier.order
        showGrowthPulse = true
        Haptics.lightTap()
    }

    private var templatePicker: some View {
        HStack(spacing: 16) {
            ForEach(ShareCardTemplate.allCases) { template in
                Button {
                    Haptics.lightTap()
                    selectedTemplate = template
                } label: {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(template.background)
                        .frame(width: 48, height: 48)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(selectedTemplate == template ? Color.accentColor : .clear, lineWidth: 3)
                        )
                }
                .accessibilityLabel(template.displayName)
            }
        }
    }

    private func renderToTempFile() {
        shareURL = nil
        guard let image = ShareCardRenderer.renderImage(text: text, template: selectedTemplate, growthValue: store.growthValue, cycleProgress: cycleProgress) else { return }
        previewImage = Image(uiImage: image)
        guard let data = image.pngData() else { return }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("png")
        do {
            try data.write(to: url)
            shareURL = url
        } catch {
            shareURL = nil
        }
    }
}

#Preview {
    ShareCardSheet(text: "Simplicity is the return to the root.")
        .environmentObject(PracticeStore())
}
