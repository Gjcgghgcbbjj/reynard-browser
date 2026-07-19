import UIKit

enum AddressBarAutocompleteFormatter {
    static func presentation(
        for result: UserDataSearchResult,
        query: String
    ) -> (
        displayText: NSAttributedString,
        committedText: String,
        submissionText: String
    )? {
        let title = result.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let strippedURL = URLUtils.strippedURLString(
            result.url.absoluteString,
            trimsTrailingSlash: true
        )
        let queryAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.label
        ]
        let completionAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.label,
            .backgroundColor: UIColor.systemGray4,
        ]
        let suffixAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: BrowserDesignTokens.Color.accent,
            .backgroundColor: UIColor.systemGray4,
        ]

        if title.hasPrefix(query) {
            let attributed = NSMutableAttributedString(
                string: String(title.prefix(query.count)),
                attributes: queryAttributes
            )
            let completion = String(title.dropFirst(query.count))
            if !completion.isEmpty {
                attributed.append(
                    NSAttributedString(
                        string: completion,
                        attributes: completionAttributes
                    )
                )
            }
            attributed.append(
                NSAttributedString(
                    string: " — \(strippedURL)",
                    attributes: suffixAttributes
                )
            )
            return (attributed, strippedURL, result.url.absoluteString)
        }

        let strippedQuery = URLUtils.normalizedURLMatchString(from: query)
        let strippedURLMatchValue = URLUtils.normalizedURLMatchString(
            from: result.url.absoluteString
        )
        guard !strippedQuery.isEmpty else {
            return nil
        }

        let completedURL: String
        if strippedURLMatchValue.hasPrefix(strippedQuery) {
            completedURL = URLUtils.autocompleteURLString(
                for: query,
                url: result.url
            ) ?? strippedURL
        } else if let matchedDomain = URLUtils.domainCompletion(
            for: strippedQuery,
            url: result.url
        ) {
            completedURL = matchedDomain
        } else {
            return nil
        }

        let attributed = NSMutableAttributedString(
            string: query,
            attributes: queryAttributes
        )
        let completion = String(completedURL.dropFirst(query.count))
        if !completion.isEmpty {
            attributed.append(
                NSAttributedString(
                    string: completion,
                    attributes: completionAttributes
                )
            )
        }
        attributed.append(
            NSAttributedString(
                string: " — \(title)",
                attributes: suffixAttributes
            )
        )
        return (attributed, completedURL, result.url.absoluteString)
    }
}
