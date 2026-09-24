import Foundation

/// `parity://todo/<name>` — deliberately naive, like the Stinsen demo's.
/// Resolution against the store happens in the coordinator that owns it,
/// so this type stays a pure parse.
enum DeepLink: Equatable {
    case todo(name: String)

    init?(url: URL) {
        guard url.scheme == "parity" else { return nil }

        // parity://todo/Buy%20milk → host "todo", path "/Buy milk"
        let segments = ([url.host()] + url.pathComponents)
            .compactMap { $0 }
            .filter { $0 != "/" && !$0.isEmpty }

        guard segments.count == 2, segments[0].lowercased() == "todo" else { return nil }
        self = .todo(name: segments[1].removingPercentEncoding ?? segments[1])
    }
}
