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

enum MovementType: String, Codable, CaseIterable, Identifiable {
    case expense = "Gasto", income = "Ingreso", transferOut = "Transferencia enviada", transferIn = "Transferencia recibida"
    case purchase = "Compra", cardPayment = "Pago de tarjeta", refund = "Devolución", interest = "Interés", fee = "Comisión"
    case loanDisbursement = "Desembolso", loanPayment = "Abono de préstamo", adjustment = "Ajuste"
    var id: String { rawValue }
    static func choices(for kind: AccountKind) -> [MovementType] {
        switch kind {
        case .debit: return [.expense, .income, .refund, .adjustment]
        case .credit: return [.purchase, .cardPayment, .refund, .interest, .fee, .adjustment]
        case .loan: return [.loanDisbursement, .loanPayment, .interest, .fee, .adjustment]
        }
    }
    var reducesDebt: Bool { self == .cardPayment || self == .loanPayment || self == .refund }
    var addsCash: Bool { self == .income || self == .refund || self == .transferIn }
}

struct FinanceMovement: Identifiable, Codable {
    var id = UUID()
    var accountID: UUID
    var title: String
    var amount: Double
    var date: Date = .now
    var isPayment: Bool = false
    var type: MovementType? = nil // nil keeps older saved records compatible
    var postingDate: Date? = nil
    var statementOverride: Date? = nil
    var notes: String = ""
    var transferGroupID: UUID? = nil
    enum CodingKeys: String, CodingKey { case id, accountID, title, amount, date, isPayment, type, postingDate, statementOverride, notes, transferGroupID }
    init(id: UUID = UUID(), accountID: UUID, title: String, amount: Double, date: Date = .now, isPayment: Bool = false, type: MovementType? = nil, postingDate: Date? = nil, statementOverride: Date? = nil, notes: String = "", transferGroupID: UUID? = nil) {
        self.id = id; self.accountID = accountID; self.title = title; self.amount = amount; self.date = date
        self.isPayment = isPayment; self.type = type; self.postingDate = postingDate; self.statementOverride = statementOverride
        self.notes = notes; self.transferGroupID = transferGroupID
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        accountID = try c.decode(UUID.self, forKey: .accountID)
        title = try c.decode(String.self, forKey: .title)
        amount = try c.decode(Double.self, forKey: .amount)
        date = try c.decode(Date.self, forKey: .date)
        isPayment = try c.decodeIfPresent(Bool.self, forKey: .isPayment) ?? false
        type = try c.decodeIfPresent(MovementType.self, forKey: .type)
        postingDate = try c.decodeIfPresent(Date.self, forKey: .postingDate)
        statementOverride = try c.decodeIfPresent(Date.self, forKey: .statementOverride)
        notes = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
        transferGroupID = try c.decodeIfPresent(UUID.self, forKey: .transferGroupID)
    }
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
