import Foundation

/// Shared between the widget extension (which registers the widget under this
/// kind) and the main app (which needs the same string to ask WidgetCenter to
/// reload it after Siri marks a practice complete).
enum WidgetKind {
    static let beadsWidget = "BeadsWidget"
}
