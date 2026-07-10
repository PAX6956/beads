import Foundation

/// A human-readable export of the Journal — distinct from `DataExporter`'s
/// JSON dump (that one's for data-portability/GDPR purposes; this one's for
/// someone who just wants their own reflections as a document they can
/// actually read, print, or keep editing in Notes/Pages/Word).
enum JournalExporter {
    static func exportMarkdown(_ entries: [JournalEntry]) -> URL? {
        var lines = ["# Beads Journal", ""]

        let formatter = DateFormatter()
        formatter.dateStyle = .long

        for entry in entries {
            lines.append("## \(formatter.string(from: entry.date))")

            if !entry.moods.isEmpty {
                let moodLine = entry.moods.map { "\($0.emoji) \($0.localizedLabel)" }.joined(separator: " · ")
                lines.append(moodLine)
            }

            if let quote = entry.associatedQuote, !quote.isEmpty {
                lines.append("")
                lines.append("> \(quote)")
            }

            if !entry.text.isEmpty {
                lines.append("")
                lines.append(entry.text)
            }

            lines.append("")
            lines.append("---")
            lines.append("")
        }

        let text = lines.joined(separator: "\n")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("beads-journal-\(Int(Date().timeIntervalSince1970))")
            .appendingPathExtension("md")
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}
