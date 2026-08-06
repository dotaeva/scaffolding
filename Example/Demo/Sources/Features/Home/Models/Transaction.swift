import Foundation

/// Route payload — Codable so HomeCoordinator can opt into
/// @Scaffoldable(codable: true) state restoration.
struct Transaction: Identifiable, Hashable, Codable {
    let id: Int
    let name: String
    let category: String
    let systemImage: String
    let amount: Decimal

    static let samples: [Transaction] = [
        Transaction(id: 0, name: "Albert", category: "Groceries", systemImage: "cart.fill", amount: -42.80),
        Transaction(id: 1, name: "Salary", category: "Income", systemImage: "banknote.fill", amount: 3_200),
        Transaction(id: 2, name: "Spotify", category: "Subscriptions", systemImage: "music.note", amount: -10.99),
        Transaction(id: 3, name: "Prague Transit", category: "Travel", systemImage: "tram.fill", amount: -1.55),
        Transaction(id: 4, name: "Café Letka", category: "Restaurants", systemImage: "cup.and.saucer.fill", amount: -6.40),
        Transaction(id: 5, name: "Refund — Alza", category: "Shopping", systemImage: "arrow.uturn.backward", amount: 129),
        Transaction(id: 6, name: "Netflix", category: "Subscriptions", systemImage: "play.rectangle.fill", amount: -15.49),
        Transaction(id: 7, name: "Shell", category: "Travel", systemImage: "fuelpump.fill", amount: -58.30),
        Transaction(id: 8, name: "Lidl", category: "Groceries", systemImage: "basket.fill", amount: -31.16),
        Transaction(id: 9, name: "Pho Bar", category: "Restaurants", systemImage: "fork.knife", amount: -14.20),
    ]

    static var categories: [String] {
        Array(Set(samples.map(\.category))).sorted()
    }
}
