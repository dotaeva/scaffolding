import Foundation

struct Holding: Identifiable, Hashable, Codable {
    let id: Int
    let symbol: String
    let name: String
    let price: Decimal
    let change: Double

    static let samples: [Holding] = [
        Holding(id: 0, symbol: "AAPL", name: "Apple", price: 248.12, change: 1.24),
        Holding(id: 1, symbol: "NVDA", name: "NVIDIA", price: 172.40, change: 3.87),
        Holding(id: 2, symbol: "VWCE", name: "FTSE All-World", price: 141.02, change: 0.42),
        Holding(id: 3, symbol: "TSLA", name: "Tesla", price: 331.55, change: -2.11),
        Holding(id: 4, symbol: "MSFT", name: "Microsoft", price: 512.83, change: 0.76),
        Holding(id: 5, symbol: "BTC", name: "Bitcoin", price: 118_450, change: 2.05),
        Holding(id: 6, symbol: "GOOG", name: "Alphabet", price: 201.66, change: 0.91),
        Holding(id: 7, symbol: "AMD", name: "AMD", price: 168.09, change: 4.52),
    ]
}
