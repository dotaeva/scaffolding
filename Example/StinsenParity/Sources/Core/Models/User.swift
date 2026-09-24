import Foundation

struct User: Codable, Equatable, Hashable, Sendable {
    let username: String
    let accessToken: String

    static let preview = User(username: "user@example.com", accessToken: "preview-token")
}
