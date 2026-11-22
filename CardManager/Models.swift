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
    var bankID: String = ""
    var network: String = "Sin especificar"
    enum CodingKeys: String, CodingKey {
        case id, name, kind, limit, used, closingDay, paymentDay, color, bankID, network
    }
    init(id: UUID = UUID(), name: String, kind: AccountKind, limit: Double, used: Double, closingDay: Int, paymentDay: Int, color: String = "green", bankID: String = "", network: String = "Sin especificar") {
        self.id = id; self.name = name; self.kind = kind; self.limit = limit
        self.used = used; self.closingDay = closingDay; self.paymentDay = paymentDay
        self.color = color; self.bankID = bankID; self.network = network
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        kind = try c.decode(AccountKind.self, forKey: .kind)
        limit = try c.decode(Double.self, forKey: .limit)
        used = try c.decode(Double.self, forKey: .used)
        closingDay = try c.decode(Int.self, forKey: .closingDay)
        paymentDay = try c.decode(Int.self, forKey: .paymentDay)
        color = try c.decodeIfPresent(String.self, forKey: .color) ?? "green"
        bankID = try c.decodeIfPresent(String.self, forKey: .bankID) ?? ""
        network = try c.decodeIfPresent(String.self, forKey: .network) ?? "Sin especificar"
    }
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
