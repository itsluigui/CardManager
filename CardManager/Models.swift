import Foundation

enum AccountKind: String, Codable, CaseIterable, Identifiable {
    case credit = "Crédito", debit = "Débito", loan = "Préstamo"
    var id: String { rawValue }
}

struct FinanceAccount: Identifiable, Codable {
    var id = UUID()
    var name: String
    var kind: AccountKind
    var limit: Double
    var used: Double
    var closingDay: Int
    var paymentDay: Int
    var color: String = "green"
    var available: Double { max(0, limit - used) }
    var utilization: Double { limit > 0 ? used / limit : 0 }
}

struct FinanceMovement: Identifiable, Codable {
    var id = UUID()
    var accountID: UUID
    var title: String
    var amount: Double
    var date: Date = .now
    var isPayment: Bool = false
}

struct FinanceData: Codable {
    var accounts: [FinanceAccount] = []
    var movements: [FinanceMovement] = []
}
