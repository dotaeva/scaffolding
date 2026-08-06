import SwiftUI

struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        IconRow(
            title: transaction.name,
            subtitle: transaction.category,
            systemImage: transaction.systemImage,
            trailing: transaction.amount.formatted(.currency(code: "EUR").sign(strategy: .always())),
            trailingTint: transaction.amount > 0 ? .green : .primary
        )
    }
}
