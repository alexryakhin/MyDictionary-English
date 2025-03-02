import SwiftUI

struct HTMLFormattedText: View {
    let attributedString: AttributedString

    init(_ htmlContent: String, font: UIFont) {
        // Parse and handle ordered list before converting to attributed string
        let processedHTML = HTMLFormattedText.parseOrderedLists(in: htmlContent)
        // Initialize the attributed string by converting from HTML and applying the font
        self.attributedString = AttributedString(fromHTML: processedHTML, applyingFont: font) ?? AttributedString("Failed to parse HTML")
    }

    var body: some View {
        Text(attributedString)
            .padding(16)
    }

    // Helper function to process ordered list HTML tags
    static func parseOrderedLists(in htmlContent: String) -> String {
        var result = htmlContent
        // Replace <ol> with custom numbering logic for ordered lists
        if let olRange = result.range(of: "<ol>") {
            result = result.replacingOccurrences(of: "<ol>", with: "")
            result = result.replacingOccurrences(of: "</ol>", with: "")
            result = enumerateListItems(in: result, startingAt: olRange.lowerBound)
        }
        return result
    }

    // Enumerate through <li> tags and add numbers to simulate ordered list
    static func enumerateListItems(in htmlContent: String, startingAt rangeStart: String.Index) -> String {
        var result = htmlContent
        var listIndex = 1
        while let liRange = result.range(of: "<li>") {
            // Replace the opening <li> tag with a numbered item, e.g., "1. ", "2. ", etc.
            let replacement = "\(listIndex). "
            result.replaceSubrange(liRange, with: replacement)

            // Remove the closing </li> tag
            if let closingLiRange = result.range(of: "</li>") {
                result.replaceSubrange(closingLiRange, with: "")
            }

            // Increment the list index for next item
            listIndex += 1
        }
        return result
    }
}

extension AttributedString {
    // Helper function to convert HTML string to SwiftUI's AttributedString and apply a font
    init?(fromHTML htmlContent: String, applyingFont font: UIFont) {
        guard let data = htmlContent.data(using: .utf8) else { return nil }

        do {
            // Convert HTML to NSAttributedString
            let nsAttributedString = try NSMutableAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.html,
                          .characterEncoding: String.Encoding.utf8.rawValue],
                documentAttributes: nil
            )

            // Apply the global font, keeping existing formatting
            nsAttributedString.enumerateAttributes(in: NSRange(location: 0, length: nsAttributedString.length), options: []) { attributes, range, _ in
                if let currentFont = attributes[.font] as? UIFont {
                    let newFontDescriptor = currentFont.fontDescriptor.withFamily(font.familyName)
                    let newFont = UIFont(descriptor: newFontDescriptor, size: font.pointSize)
                    nsAttributedString.addAttribute(.font, value: newFont, range: range)
                }
            }

            // Convert NSAttributedString to SwiftUI's AttributedString
            self.init(nsAttributedString)
        } catch {
            print("Error converting HTML to AttributedString: \(error)")
            return nil
        }
    }
}

