import SwiftUI

struct ShareCardSheet: View {
    let text: String

    @Environment(\.dismiss) private var dismiss
    @State private var selectedTemplate: ShareCardTemplate = .inkWash
    @State private var renderedImage: UIImage?
    @State private var isShowingActivitySheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                ShareCardView(text: text, template: selectedTemplate)
                    .shadow(radius: 12, y: 6)
                    .padding(.top, 16)

                templatePicker

                Button {
                    share()
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Ripple Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $isShowingActivitySheet) {
                if let renderedImage {
                    ActivityShareSheet(items: [renderedImage])
                }
            }
        }
    }

    private var templatePicker: some View {
        HStack(spacing: 16) {
            ForEach(ShareCardTemplate.allCases) { template in
                Button {
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

    private func share() {
        renderedImage = ShareCardRenderer.renderImage(text: text, template: selectedTemplate)
        isShowingActivitySheet = renderedImage != nil
    }
}

#Preview {
    ShareCardSheet(text: "Simplicity is the return to the root.")
}
