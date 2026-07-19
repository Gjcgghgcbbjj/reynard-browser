import Foundation

public enum URLRedactor {
    public static func redact(_ value: String?) -> String? {
        guard let value else {
            return nil
        }

        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty,
              let components = URLComponents(string: trimmedValue),
              let scheme = components.scheme?.lowercased(),
              !scheme.isEmpty else {
            return nil
        }

        guard let host = components.host?.lowercased(), !host.isEmpty else {
            return "\(scheme):"
        }

        return "\(scheme)://\(host)"
    }
}
