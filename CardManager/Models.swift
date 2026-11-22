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

struct InstallmentPlan: Identifiable, Codable {
    var id = UUID()
    var accountID: UUID
    var title: String
    var principal: Double
    var totalMonths: Int
    var paidMonths: Int
    var monthlyAmount: Double
    var nextPaymentDate: Date
    var isInterestFree: Bool
    var notes: String = ""
    var remainingMonths: Int { max(0, totalMonths - paidMonths) }
    var remainingBalance: Double { max(0, Double(remainingMonths) * monthlyAmount) }
    var isFinished: Bool { remainingMonths == 0 }
}

struct PaymentScheduleOverride: Identifiable, Codable {
    var id: UUID = UUID()
    var planID: UUID
    var installment: Int
    var dueDate: Date
    var amount: Double
    var paidAmount: Double = 0
    var paidDate: Date? = nil
}

struct FinanceData: Codable {
    var accounts: [FinanceAccount] = []
    var movements: [FinanceMovement] = []
    var plans: [InstallmentPlan] = []
    var scheduleOverrides: [PaymentScheduleOverride] = []
    enum CodingKeys: String, CodingKey { case accounts, movements, plans, scheduleOverrides }
    init(accounts: [FinanceAccount] = [], movements: [FinanceMovement] = [], plans: [InstallmentPlan] = []) {
        self.accounts = accounts; self.movements = movements; self.plans = plans
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        accounts = try c.decodeIfPresent([FinanceAccount].self, forKey: .accounts) ?? []
        movements = try c.decodeIfPresent([FinanceMovement].self, forKey: .movements) ?? []
        plans = try c.decodeIfPresent([InstallmentPlan].self, forKey: .plans) ?? []
        scheduleOverrides = try c.decodeIfPresent([PaymentScheduleOverride].self, forKey: .scheduleOverrides) ?? []
    }
}
