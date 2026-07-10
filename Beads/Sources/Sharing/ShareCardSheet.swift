import SwiftUI
import PhotosUI
import Photos

struct ShareCardSheet: View {
    let text: String

    @EnvironmentObject private var store: PracticeStore
    @EnvironmentObject private var purchases: PurchaseManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTemplate: ShareCardTemplate = .inkWash
    @State private var customImage: UIImage?
    @State private var customImageOpacities: ImageContrast.RegionOpacities?
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var showPhotoPicker = false
    @State private var showPaywall = false
    @State private var renderedImage: UIImage?
    @State private var previewImage: Image?
    @State private var saveState: SaveState = .idle
    @State private var showGrowthPulse = false
    @State private var leveledUp = false

    private enum SaveState {
        case idle, saving, success, failure
    }

    var body: some View {
        NavigationStack {
            // The share action now lives in the toolbar, next to Close —
            // pinning a big circular button above the template row crowded
            // the picker on most phones and looked out of place next to it.
            ScrollView {
                VStack(spacing: 20) {
                    ShareCardView(text: text, template: selectedTemplate, customBackground: customImage, customBackgroundOpacities: customImageOpacities, growthValue: store.growthValue, size: 300)
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
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    saveButton
                    shareButton
                }
            }
            .task {
                renderPreview()
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

    // Writes straight to the system Photos library (Camera Roll) via
    // PHPhotoLibrary — independent of whatever "save" behavior a
    // third-party app's own share extension happens to offer, and not a
    // Shared Album (a separate, opt-in iCloud feature).
    @ViewBuilder
    private var saveButton: some View {
        Button {
            Task { await saveToPhotos() }
        } label: {
            Image(systemName: saveIconName)
        }
        .accessibilityLabel("Save to Photos")
        .disabled(renderedImage == nil || saveState == .saving)
    }

    private var saveIconName: String {
        switch saveState {
        case .idle, .saving: return "square.and.arrow.down"
        case .success: return "checkmark"
        case .failure: return "exclamationmark.triangle"
        }
    }

    private func saveToPhotos() async {
        guard let renderedImage else { return }
        saveState = .saving
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: renderedImage)
            }
            saveState = .success
            Haptics.success()
        } catch {
            saveState = .failure
            Haptics.warning()
        }
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        saveState = .idle
    }

    @ViewBuilder
    private var shareButton: some View {
        if let previewImage {
            // Sharing the rendered `Image` directly (not a file URL) is what
            // makes "Save to Photos" show up and hands other apps — X's
            // compose sheet included — real image data instead of a file
            // reference that not every share extension knows how to unpack.
            ShareLink(item: previewImage, preview: SharePreview(text, image: previewImage)) {
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
                        customImageOpacities = nil
                        renderPreview()
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
        // Measured from the actual photo, not guessed — see ImageContrast.
        customImageOpacities = ImageContrast.regionOpacities(for: image)
        renderPreview()
    }

    private func renderPreview() {
        guard let image = ShareCardRenderer.renderImage(text: text, template: selectedTemplate, customBackground: customImage, customBackgroundOpacities: customImageOpacities, growthValue: store.growthValue) else { return }
        renderedImage = image
        previewImage = Image(uiImage: image)
    }
}

#Preview {
    ShareCardSheet(text: "Simplicity is the return to the root.")
        .environmentObject(PracticeStore())
        .environmentObject(PurchaseManager())
}
