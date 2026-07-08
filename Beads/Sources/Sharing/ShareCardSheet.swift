import SwiftUI
import PhotosUI

struct ShareCardSheet: View {
    let text: String

    @EnvironmentObject private var store: PracticeStore
    @EnvironmentObject private var purchases: PurchaseManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTemplate: ShareCardTemplate = .inkWash
    @State private var customImage: UIImage?
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var showPhotoPicker = false
    @State private var showPaywall = false
    @State private var shareURL: URL?
    @State private var previewImage: Image?
    @State private var showGrowthPulse = false
    @State private var leveledUp = false

    private var cycleProgress: Int { store.beadCount % BeadRingView.ringCapacity }

    var body: some View {
        NavigationStack {
            // The share action now lives in the toolbar, next to Close —
            // pinning a big circular button above the template row crowded
            // the picker on most phones and looked out of place next to it.
            ScrollView {
                VStack(spacing: 20) {
                    ShareCardView(text: text, template: selectedTemplate, customBackground: customImage, growthValue: store.growthValue, cycleProgress: cycleProgress, size: 300)
                        .shadow(radius: 12, y: 6)
                        .padding(.top, 16)

                    templatePicker
                }
                .padding(.bottom, 12)
            }
            .navigationTitle("Ripple Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    shareButton
                }
            }
            .task {
                renderToTempFile()
            }
            .onChange(of: photoPickerItem) { newItem in
                Task { await loadPickedPhoto(newItem) }
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: $photoPickerItem, matching: .images)
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .growthPulse(isPresented: $showGrowthPulse, tier: store.currentTierInfo?.tier, beyondIntensity: store.currentTierInfo?.beyondIntensity ?? 0, leveledUp: leveledUp)
        }
    }

    @ViewBuilder
    private var shareButton: some View {
        if let shareURL {
            ShareLink(item: shareURL, preview: SharePreview(text, image: previewImage ?? Image(systemName: "photo"))) {
                Image(systemName: "square.and.arrow.up")
            }
            .accessibilityLabel("Share")
            .simultaneousGesture(TapGesture().onEnded { recordShareGrowth() })
        } else {
            ProgressView()
        }
    }

    private func recordShareGrowth() {
        let previousTier = store.currentTierInfo?.tier.order
        store.recordShare()
        leveledUp = previousTier != store.currentTierInfo?.tier.order
        showGrowthPulse = true
        Haptics.lightTap()
    }

    // 9 swatches (photo + 8 templates) no longer fit one row now that the 5
    // subscription templates were added, so this scrolls horizontally.
    private var templatePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                customPhotoButton

                ForEach(ShareCardTemplate.allCases) { template in
                    Button {
                        Haptics.lightTap()
                        if template.isPro && !purchases.isPro {
                            showPaywall = true
                            return
                        }
                        selectedTemplate = template
                        customImage = nil
                        renderToTempFile()
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(template.background)
                            if template.isPro && !purchases.isPro {
                                Color.black.opacity(0.25)
                                Image(systemName: "lock.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(customImage == nil && selectedTemplate == template ? Color.accentColor : .clear, lineWidth: 3)
                        )
                    }
                    .accessibilityLabel(template.isPro && !purchases.isPro ? "\(template.displayName) — Pro" : template.displayName)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    // Tapping while not subscribed opens the paywall instead of the system
    // photo picker — gated here rather than with `.disabled`, since a
    // disabled control can leave its tap gesture in an ambiguous state.
    private var customPhotoButton: some View {
        Button {
            Haptics.lightTap()
            if purchases.isPro {
                showPhotoPicker = true
            } else {
                showPaywall = true
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.secondary.opacity(0.15))
                Image(systemName: purchases.isPro ? "photo.badge.plus" : "lock.fill")
                    .foregroundStyle(.secondary)
            }
            .frame(width: 48, height: 48)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(customImage != nil ? Color.accentColor : .clear, lineWidth: 3)
            )
        }
        .accessibilityLabel(purchases.isPro ? "Choose your own photo" : "Unlock custom photo backgrounds")
    }

    private func loadPickedPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) else { return }
        customImage = image
        renderToTempFile()
    }

    private func renderToTempFile() {
        shareURL = nil
        guard let image = ShareCardRenderer.renderImage(text: text, template: selectedTemplate, customBackground: customImage, growthValue: store.growthValue, cycleProgress: cycleProgress) else { return }
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
        .environmentObject(PurchaseManager())
}
