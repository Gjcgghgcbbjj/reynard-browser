import Foundation

public struct StabilityEvent: Codable, Equatable, Sendable {
    public enum Category: String, Codable, Sendable {
        case startup
        case jit
        case process
        case session
        case persistence
        case memory
        case recovery
    }

    public let id: UUID
    public let timestamp: Date
    public let category: Category
    public let name: String
    public let metadata: [String: String]

    public init(
        id: UUID,
        timestamp: Date,
        category: Category,
        name: String,
        metadata: [String: String]
    ) {
        self.id = id
        self.timestamp = timestamp
        self.category = category
        self.name = name
        self.metadata = metadata
    }
}
