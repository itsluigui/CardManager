import Foundation
import Combine

@MainActor final class FinanceStore: ObservableObject {
    @Published private(set) var data = FinanceData()
    private let fileURL: URL

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        fileURL = base.appendingPathComponent("cardmanager.json")
        load()
    }

    var accounts: [FinanceAccount] { data.accounts }
    var plans: [InstallmentPlan] { data.plans }
    func plans(for id: UUID) -> [InstallmentPlan] { data.plans.filter { $0.accountID == id } }
    func addPlan(_ plan: InstallmentPlan) { data.plans.append(plan); save() }
    func updatePlan(_ plan: InstallmentPlan) {
        guard let i = data.plans.firstIndex(where: { $0.id == plan.id }) else { return }
        data.plans[i] = plan
        // Existing per-installment overrides remain tied to their installment number.
        data.scheduleOverrides.removeAll { $0.planID == plan.id && $0.installment > plan.totalMonths }
        save()
    }
    func deletePlan(_ id: UUID) {
        data.plans.removeAll { $0.id == id }
        data.scheduleOverrides.removeAll { $0.planID == id }
        save()
    }
    var debitBalance: Double { data.accounts.filter { $0.kind == .debit }.reduce(0) { $0 + $1.available } }
    var totalLoanDebt: Double { data.accounts.filter { $0.kind == .loan }.reduce(0) { $0 + $1.used } }
    var totalLoanOriginal: Double { data.accounts.filter { $0.kind == .loan }.reduce(0) { $0 + $1.limit } }
    var totalLoanRepaid: Double { max(0, totalLoanOriginal - totalLoanDebt) }
    var availableCredit: Double { max(0, totalLimit - totalUsedCredit) }
    var netBalance: Double { debitBalance - totalDebt }
    var debitAccounts: [FinanceAccount] { accounts.filter { $0.kind == .debit } }
    var creditAccounts: [FinanceAccount] { accounts.filter { $0.kind == .credit } }
    var loanAccounts: [FinanceAccount] { accounts.filter { $0.kind == .loan } }
    var creditUtilization: Double { totalLimit > 0 ? totalUsedCredit / totalLimit : 0 }
    var amountToTarget: Double { max(0, totalUsedCredit - totalLimit * 0.30) }
    var monthlyCommitments: Double {
        plans.reduce(0) { sum, plan in
            let unpaid = schedule(for: plan).filter { $0.paidAmount < $0.amount - 0.005 }
            return sum + (unpaid.first.map { max(0, $0.amount - $0.paidAmount) } ?? 0)
        }
    }
    func schedule(for plan: InstallmentPlan) -> [PaymentScheduleOverride] {
        let calendar = Calendar.current
        let anchor = calendar.date(byAdding: .month, value: -plan.paidMonths, to: plan.nextPaymentDate) ?? plan.nextPaymentDate
        return (1...max(1, plan.totalMonths)).map { n in
            if let saved = data.scheduleOverrides.first(where: { $0.planID == plan.id && $0.installment == n }) { return saved }
            let due = calendar.date(byAdding: .month, value: n - 1, to: anchor) ?? anchor
            return PaymentScheduleOverride(planID: plan.id, installment: n, dueDate: due,
                amount: plan.monthlyAmount, paidAmount: n <= plan.paidMonths ? plan.monthlyAmount : 0)
        }
    }
    func saveInstallment(_ entry: PaymentScheduleOverride) {
        guard data.plans.contains(where: { $0.id == entry.planID }), entry.amount > 0,
              entry.paidAmount >= 0, entry.paidAmount <= entry.amount else { return }
        if let i = data.scheduleOverrides.firstIndex(where: { $0.planID == entry.planID && $0.installment == entry.installment }) {
            data.scheduleOverrides[i] = entry
        } else { data.scheduleOverrides.append(entry) }
        save()
    }
    func recordInstallmentPayment(planID: UUID, installment: Int, amount: Double, date: Date) {
        guard let plan = data.plans.first(where: { $0.id == planID }),
              let current = schedule(for: plan).first(where: { $0.installment == installment }),
              amount > 0, current.paidAmount + amount <= current.amount + 0.001 else { return }
        var changed = current
        changed.paidAmount = min(changed.amount, current.paidAmount + amount)
        changed.paidDate = date
        saveInstallment(changed)
    }
    func transfer(from sourceID: UUID, to targetID: UUID, amount: Double, date: Date) {
        guard sourceID != targetID, amount > 0,
              let source = data.accounts.firstIndex(where: { $0.id == sourceID }),
              let target = data.accounts.firstIndex(where: { $0.id == targetID }),
              data.accounts[source].kind == .debit, data.accounts[target].kind == .debit,
              data.accounts[source].available >= amount else { return }
        // Debit balance = limit - used. A transfer changes used, not limit.
        data.accounts[source].used += amount
        data.accounts[target].used -= amount
        let group = UUID()
        let ref = group.uuidString.prefix(6)
        data.movements.append(FinanceMovement(accountID: sourceID, title: "Transferencia enviada #\(ref)", amount: amount, date: date, isPayment: false, type: .transferOut, transferGroupID: group))
        data.movements.append(FinanceMovement(accountID: targetID, title: "Transferencia recibida #\(ref)", amount: amount, date: date, isPayment: true, type: .transferIn, transferGroupID: group))
        save()
    }
    func markInstallmentPaid(_ id: UUID) {
        guard let index = data.plans.firstIndex(where: { $0.id == id }), !data.plans[index].isFinished else { return }
        data.plans[index].paidMonths += 1
        if let next = Calendar.current.date(byAdding: .month, value: 1, to: data.plans[index].nextPaymentDate) { data.plans[index].nextPaymentDate = next }
        save()
    }
    enum BackupError: LocalizedError {
        case invalidData, duplicateAccounts, missingAccounts
        var errorDescription: String? {
            switch self {
            case .invalidData: return "El archivo no es un respaldo JSON compatible de Card Manager."
            case .duplicateAccounts: return "El respaldo contiene identificadores de cuenta duplicados."
            case .missingAccounts: return "El respaldo contiene movimientos o planes sin su cuenta correspondiente."
            }
        }
    }
    func exportBackup() throws -> URL {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("CardManager-Backup-\(Int(Date().timeIntervalSince1970)).json")
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]; encoder.dateEncodingStrategy = .deferredToDate
        try encoder.encode(data).write(to: file, options: .atomic)
        return file
    }
    func importBackup(from url: URL) throws {
        let permitted = url.startAccessingSecurityScopedResource()
        defer { if permitted { url.stopAccessingSecurityScopedResource() } }
        let bytes = try Data(contentsOf: url)
        guard let decoded = try? JSONDecoder().decode(FinanceData.self, from: bytes) else { throw BackupError.invalidData }
        let ids = Set(decoded.accounts.map(\.id))
        guard ids.count == decoded.accounts.count else { throw BackupError.duplicateAccounts }
        guard decoded.movements.allSatisfy({ ids.contains($0.accountID) }) && decoded.plans.allSatisfy({ ids.contains($0.accountID) }) else { throw BackupError.missingAccounts }
        let planIDs = Set(decoded.plans.map(\.id))
        guard decoded.scheduleOverrides.allSatisfy({ planIDs.contains($0.planID) && $0.amount > 0 && $0.paidAmount >= 0 && $0.paidAmount <= $0.amount }) else { throw BackupError.invalidData }
        // Validate before replacing, then atomically persist the complete new dataset.
        let encoded = try JSONEncoder().encode(decoded)
        try encoded.write(to: fileURL, options: .atomic)
        data = decoded
        objectWillChange.send()
    }
    var movements: [FinanceMovement] { data.movements.sorted { $0.date > $1.date } }
    var totalDebt: Double { data.accounts.filter { $0.kind != .debit }.reduce(0) { $0 + $1.used } }
    var totalLimit: Double { data.accounts.filter { $0.kind == .credit }.reduce(0) { $0 + $1.limit } }
    var totalUsedCredit: Double { data.accounts.filter { $0.kind == .credit }.reduce(0) { $0 + $1.used } }

    func addAccount(_ account: FinanceAccount) { data.accounts.append(account); save() }
    func updateAccount(_ account: FinanceAccount) {
        guard let index = data.accounts.firstIndex(where: { $0.id == account.id }) else { return }
        data.accounts[index] = account
        save()
    }
    func deleteAccount(_ id: UUID) {
        data.accounts.removeAll { $0.id == id }
        data.movements.removeAll { $0.accountID == id }
        let planIDs = Set(data.plans.filter { $0.accountID == id }.map(\.id))
        data.scheduleOverrides.removeAll { planIDs.contains($0.planID) }
        data.plans.removeAll { $0.accountID == id }
        save()
    }
    // A single sign convention: positive increases outstanding debt or debit spending.
    // Legacy records without a type keep their original sign semantics.
    func movementEffect(_ movement: FinanceMovement, kind: AccountKind) -> Double {
        guard let type = movement.type else { return movement.isPayment ? -movement.amount : movement.amount }
        switch kind {
        case .debit:
            return type.addsCash ? -movement.amount : movement.amount
        case .credit, .loan:
            return type.reducesDebt ? -movement.amount : movement.amount
        }
    }
    private func applying(_ movement: FinanceMovement, multiplier: Double) -> Bool {
        guard let i = data.accounts.firstIndex(where: { $0.id == movement.accountID }), movement.amount.isFinite, movement.amount > 0 else { return false }
        let effect = movementEffect(movement, kind: data.accounts[i].kind) * multiplier
        let resulting = data.accounts[i].used + effect
        guard resulting.isFinite else { return false }
        if data.accounts[i].kind == .debit {
            guard data.accounts[i].limit - resulting >= -0.005 else { return false }
            data.accounts[i].used = resulting
        } else {
            // No silent clamping: a failed edit must not corrupt the original balance.
            guard resulting >= -0.005 else { return false }
            data.accounts[i].used = max(0, resulting)
        }
        return true
    }
    @discardableResult func addMovement(_ movement: FinanceMovement) -> Bool {
        guard applying(movement, multiplier: 1) else { return false }
        data.movements.append(movement); save(); return true
    }
    @discardableResult func updateMovement(_ changed: FinanceMovement) -> Bool {
        guard let index = data.movements.firstIndex(where: { $0.id == changed.id }),
              data.movements[index].transferGroupID == nil else { return false }
        let old = data.movements[index]
        // Revert first, apply replacement, roll back if validation fails.
        guard applying(old, multiplier: -1) else { return false }
        guard applying(changed, multiplier: 1) else {
            _ = applying(old, multiplier: 1)
            return false
        }
        data.movements[index] = changed; save(); return true
    }
    func deleteMovement(_ id: UUID) {
        guard let movement = data.movements.first(where: { $0.id == id }) else { return }
        let items: [FinanceMovement]
        if let group = movement.transferGroupID {
            items = data.movements.filter { $0.transferGroupID == group }
        } else if let marker = movement.title.split(separator: "#").last,
                  (movement.title.hasPrefix("Transferencia enviada #") || movement.title.hasPrefix("Transferencia recibida #")) {
            let key = String(marker)
            items = data.movements.filter { ($0.title.hasPrefix("Transferencia enviada #") || $0.title.hasPrefix("Transferencia recibida #")) && $0.title.hasSuffix("#" + key) }
        } else { items = [movement] }
        for m in items { _ = applying(m, multiplier: -1) }
        let ids = Set(items.map(\.id))
        data.movements.removeAll { ids.contains($0.id) }; save()
    }

    func statementDate(for movement: FinanceMovement, account: FinanceAccount) -> Date {
        if let override = movement.statementOverride { return Calendar.current.startOfDay(for: override) }
        let cal = Calendar.current
        let posting = movement.postingDate ?? movement.date
        let parts = cal.dateComponents([.year, .month, .day], from: posting)
        let monthStart = cal.date(from: DateComponents(year: parts.year, month: parts.month, day: 1)) ?? posting
        let nextMonth = cal.date(byAdding: .month, value: (parts.day ?? 1) > account.closingDay ? 1 : 0, to: monthStart) ?? monthStart
        let days = cal.range(of: .day, in: .month, for: nextMonth)?.count ?? 28
        return cal.date(byAdding: .day, value: min(max(account.closingDay, 1), days) - 1, to: nextMonth) ?? nextMonth
    }
    func paymentDueDate(for statement: Date, account: FinanceAccount) -> Date {
        let cal = Calendar.current
        let day = cal.component(.day, from: statement)
        let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: statement)) ?? statement
        let targetMonth = cal.date(byAdding: .month, value: account.paymentDay <= day ? 1 : 0, to: monthStart) ?? monthStart
        let maxDay = cal.range(of: .day, in: .month, for: targetMonth)?.count ?? 28
        return cal.date(byAdding: .day, value: min(max(account.paymentDay, 1), maxDay) - 1, to: targetMonth) ?? targetMonth
    }
    func statementPurchases(accountID: UUID, statement: Date) -> Double {
        guard let account = accounts.first(where: { $0.id == accountID && $0.kind == .credit }) else { return 0 }
        let cal = Calendar.current
        return data.movements.filter { $0.accountID == accountID && cal.isDate(statementDate(for: $0, account: account), inSameDayAs: statement) }
            .reduce(0) { $0 + movementEffect($1, kind: .credit) }
    }
    private func load() {
        guard let bytes = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode(FinanceData.self, from: bytes) else { return }
        data = decoded
    }
    private func save() {
        guard let bytes = try? JSONEncoder().encode(data) else { return }
        try? bytes.write(to: fileURL, options: .atomic)
        objectWillChange.send()
    }
}
