import Foundation

struct Order: Identifiable, Hashable {
    let id = UUID()
    let holding: Holding
    let shares: Int

    var total: Decimal { holding.price * Decimal(shares) }
}
