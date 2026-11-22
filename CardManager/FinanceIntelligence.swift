import Foundation

/// Date-only billing rules. Dates calculated here are estimates until a bank statement is entered.
enum FinanceCycleMath {
    static func monthStart(_ date: Date, calendar: Calendar = .current) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? calendar.startOfDay(for: date)
    }
    static func monthDate(_ month: Date, day: Int, calendar: Calendar = .current) -> Date {
        let base = monthStart(month, calendar: calendar)
        let count = calendar.range(of: .day, in: .month, for: base)?.count ?? 28
        return calendar.date(byAdding: .day, value: max(1, min(day, count)) - 1, to: base) ?? base
    }
    static func statementDate(posting: Date, closingDay: Int, calendar: Calendar = .current) -> Date {
        let base = monthStart(posting, calendar: calendar)
        let close = monthDate(base, day: closingDay, calendar: calendar)
        if calendar.startOfDay(for: posting) <= close { return close }
        return monthDate(calendar.date(byAdding: .month, value: 1, to: base) ?? base, day: closingDay, calendar: calendar)
    }
    static func paymentDate(statement: Date, paymentDay: Int, calendar: Calendar = .current) -> Date {
        let base = monthStart(statement, calendar: calendar)
        let candidate = monthDate(base, day: paymentDay, calendar: calendar)
        if candidate > calendar.startOfDay(for: statement) { return candidate }
        return monthDate(calendar.date(byAdding: .month, value: 1, to: base) ?? base, day: paymentDay, calendar: calendar)
    }
    static func inMonth(_ date: Date, of month: Date, calendar: Calendar = .current) -> Bool {
        calendar.isDate(date, equalTo: month, toGranularity: .month)
    }
}

/// A payment that will actually be due, only counted when its amount is known.
struct MonthObligation: Identifiable {
    enum Reliability { case confirmed, scheduled }
    let id: String
    let accountID: UUID
    let title: String
    let subtitle: String
    let amount: Double
    let dueDate: Date
    let reliability: Reliability
    let isCard: Bool
}

struct MonthOverview {
    let date: Date
    let obligations: [MonthObligation]
    let unverifiedCards: [UUID]
    let unplannedLoans: [UUID]
    let informationalMSI: Double
    var confirmedCardTotal: Double { obligations.filter(\.isCard).reduce(0) { $0 + $1.amount } }
    var scheduledLoanTotal: Double { obligations.filter { !$0.isCard }.reduce(0) { $0 + $1.amount } }
    var combinedKnownTotal: Double { confirmedCardTotal + scheduledLoanTotal }
    var hasUnknownAmounts: Bool { !unverifiedCards.isEmpty || !unplannedLoans.isEmpty }
}

/// Accounting sign rules shared by the app and the standalone test suite.
/// Positive `used` means credit debt / debit cash spent from the reference balance.
enum FinanceLedgerMath {
    static func effect(_ movement: FinanceMovement, kind: AccountKind) -> Double {
        guard let type = movement.type else { return movement.isPayment ? -movement.amount : movement.amount }
        switch kind {
        case .debit: return type.addsCash ? -movement.amount : movement.amount
        case .credit, .loan: return type.reducesDebt ? -movement.amount : movement.amount
        }
    }
    static func adjustedUsed(account: FinanceAccount, movement: FinanceMovement, multiplier: Double) -> Double? {
        guard movement.amount.isFinite, movement.amount > 0, multiplier.isFinite else { return nil }
        let result = account.used + effect(movement, kind: account.kind) * multiplier
        guard result.isFinite else { return nil }
        if account.kind == .debit { return account.limit - result >= -0.005 ? result : nil }
        return result >= -0.005 ? max(0, result) : nil
    }
}
