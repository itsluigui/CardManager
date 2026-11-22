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
    var statements: [BillingStatement] { data.statements }
    func statements(for accountID: UUID) -> [BillingStatement] {
        data.statements.filter { $0.accountID == accountID }.sorted { $0.dueDate > $1.dueDate }
    }
    @discardableResult func upsertStatement(_ item: BillingStatement) -> Bool {
        guard accounts.contains(where: { $0.id == item.accountID && $0.kind == .credit }),
              item.amountToAvoidInterest.isFinite, item.amountToAvoidInterest >= 0,
              item.minimumPayment.isFinite, item.minimumPayment >= 0,
              item.statementBalance.isFinite, item.statementBalance >= 0,
              item.paidAmount.isFinite, item.paidAmount >= 0,
              item.paidAmount <= item.amountToAvoidInterest + 0.001,
              item.dueDate >= item.closingDate else { return false }
        let linked = data.movements.filter { $0.linkedStatementID == item.id }.reduce(0) { $0 + $1.amount }
        guard item.paidAmount + 0.005 >= linked else { return false }
        if let i = data.statements.firstIndex(where: { $0.id == item.id }) { data.statements[i] = item }
        else {
            guard !data.statements.contains(where: {
                $0.accountID == item.accountID && Calendar.current.isDate($0.closingDate, inSameDayAs: item.closingDate)
            }) else { return false }
            data.statements.append(item)
        }
        save(); return true
    }
    @discardableResult func deleteStatement(_ id: UUID) -> Bool {
        guard !data.movements.contains(where: { $0.linkedStatementID == id }) else { return false }
        data.statements.removeAll { $0.id == id }; save(); return true
    }
    func monthOverview(for month: Date) -> MonthOverview {
        let confirmed = data.statements.filter { FinanceCycleMath.inMonth($0.dueDate, of: month) && $0.pending > 0.005 }
        let billItems = confirmed.compactMap { bill -> MonthObligation? in
            guard let acc = accounts.first(where: { $0.id == bill.accountID && $0.kind == .credit }) else { return nil }
            return MonthObligation(id: bill.id.uuidString, accountID: acc.id, title: acc.name, subtitle: "Estado de cuenta confirmado", amount: bill.pending, dueDate: bill.dueDate, reliability: .confirmed, isCard: true)
        }
        let loanItems: [MonthObligation] = plans.compactMap { plan in
            guard accounts.contains(where: { $0.id == plan.accountID && $0.kind == .loan }) else { return nil }
            return plan
        }.flatMap { plan in
            schedule(for: plan).filter { FinanceCycleMath.inMonth($0.dueDate, of: month) && $0.paidAmount < $0.amount - 0.005 }
                .map { entry in
                    MonthObligation(id: plan.id.uuidString + "-" + String(entry.installment), accountID: plan.accountID, title: plan.title,
                                    subtitle: "Préstamo · cuota \(entry.installment)/\(plan.totalMonths)", amount: max(0, entry.amount - entry.paidAmount),
                                    dueDate: entry.dueDate, reliability: .scheduled, isCard: false)
                }
        }
        let msi = plans.filter { plan in accounts.contains(where: { $0.id == plan.accountID && $0.kind == .credit }) }
            .flatMap { schedule(for: $0) }
            .filter { FinanceCycleMath.inMonth($0.dueDate, of: month) }
            .reduce(0) { $0 + max(0, $1.amount - $1.paidAmount) }

        let monthEnd = FinanceCycleMath.monthEnd(month)
        var missingItems: [PlannerStatusItem] = []
        var futureItems: [PlannerStatusItem] = []

        for card in creditAccounts where card.used > 0.005 {
            if data.statements.contains(where: { $0.accountID == card.id && FinanceCycleMath.inMonth($0.dueDate, of: month) && $0.pending > 0.005 }) {
                continue
            }
            let futureStatement = data.statements
                .filter { $0.accountID == card.id && $0.pending > 0.005 && $0.dueDate > monthEnd }
                .sorted { $0.dueDate < $1.dueDate }
                .first
            if let bill = futureStatement {
                futureItems.append(PlannerStatusItem(
                    id: "future-card-\(card.id.uuidString)",
                    accountID: card.id,
                    title: card.name,
                    detail: "Ya hay un estado de cuenta capturado. Próximo vencimiento: \(bill.dueDate.formatted(date: .abbreviated, time: .omitted)).",
                    actionLabel: "Ver siguiente",
                    dueDate: bill.dueDate,
                    kind: .nextCardStatement
                ))
            } else if !data.statements.contains(where: { $0.accountID == card.id && FinanceCycleMath.inMonth($0.dueDate, of: month) && $0.pending <= 0.005 }) {
                missingItems.append(PlannerStatusItem(
                    id: "missing-card-\(card.id.uuidString)",
                    accountID: card.id,
                    title: card.name,
                    detail: "No hay pago confirmado para este mes. Captura el corte o el pago para no generar intereses.",
                    actionLabel: "Capturar corte",
                    dueDate: nil,
                    kind: .missingCardStatement
                ))
            }
        }

        for loan in loanAccounts where loan.used > 0.005 {
            let loanPlans = plans(for: loan.id)
            if loanPlans.isEmpty {
                missingItems.append(PlannerStatusItem(
                    id: "missing-loan-\(loan.id.uuidString)",
                    accountID: loan.id,
                    title: loan.name,
                    detail: "No hay calendario de cuotas. Registra las mensualidades para saber qué toca pagar en el mes.",
                    actionLabel: "Agregar plan",
                    dueDate: nil,
                    kind: .missingLoanSchedule
                ))
                continue
            }
            let nextLoanEntry: (InstallmentPlan, PaymentScheduleOverride)? = loanPlans
                .compactMap { plan in
                    schedule(for: plan)
                        .filter { $0.paidAmount < $0.amount - 0.005 }
                        .sorted { $0.dueDate < $1.dueDate }
                        .first
                        .map { (plan, $0) }
                }
                .sorted { $0.1.dueDate < $1.1.dueDate }
                .first
            guard let nextLoanEntry else { continue }
            let nextDue = nextLoanEntry.1.dueDate
            if !FinanceCycleMath.inMonth(nextDue, of: month) && nextDue > monthEnd {
                futureItems.append(PlannerStatusItem(
                    id: "future-loan-\(loan.id.uuidString)",
                    accountID: loan.id,
                    title: loan.name,
                    detail: "Calendario registrado. Próxima cuota: \(nextDue.formatted(date: .abbreviated, time: .omitted)).",
                    actionLabel: "Ver calendario",
                    dueDate: nextDue,
                    kind: .nextLoanInstallment
                ))
            }
        }

        return MonthOverview(
            date: month,
            obligations: (billItems + loanItems).sorted { $0.dueDate < $1.dueDate },
            missingItems: missingItems,
            futureItems: futureItems,
            informationalMSI: msi
        )
    }
    func debitIncome(in month: Date) -> Double {
        data.movements.filter { m in
            guard let a = accounts.first(where: { $0.id == m.accountID && $0.kind == .debit }) else { return false }
            return a.kind == .debit && FinanceCycleMath.inMonth(m.date, of: month) && (m.type == .income || m.type == .refund)
        }.reduce(0) { $0 + $1.amount }
    }
    func debitExpense(in month: Date) -> Double {
        data.movements.filter { m in
            accounts.contains(where: { $0.id == m.accountID && $0.kind == .debit }) && FinanceCycleMath.inMonth(m.date, of: month) && (m.type == .expense || (m.type == nil && !m.isPayment))
        }.reduce(0) { $0 + $1.amount }
    }
    private func isOwnTransfer(_ movement: FinanceMovement) -> Bool {
        guard let group = movement.transferGroupID else { return false }
        return data.movements.contains { linked in
            linked.transferGroupID == group && linked.accountID != movement.accountID &&
            accounts.contains(where: { $0.id == linked.accountID && $0.kind == .debit })
        }
    }
    func debitInflows(in month: Date) -> Double {
        data.movements.filter { m in
            accounts.contains(where: { $0.id == m.accountID && $0.kind == .debit }) &&
            FinanceCycleMath.inMonth(m.date, of: month) && !isOwnTransfer(m) &&
            (m.type == .income || m.type == .transferIn || m.type == .refund || (m.type == nil && m.isPayment))
        }.reduce(0) { $0 + $1.amount }
    }
    func debitOutflows(in month: Date) -> Double {
        data.movements.filter { m in
            accounts.contains(where: { $0.id == m.accountID && $0.kind == .debit }) &&
            FinanceCycleMath.inMonth(m.date, of: month) && !isOwnTransfer(m) &&
            (m.type == .expense || m.type == .transferOut || (m.type == nil && !m.isPayment))
        }.reduce(0) { $0 + $1.amount }
    }
    func spendByCategory(in month: Date) -> [(name: String, total: Double)] {
        let eligible = data.movements.filter { m in
            FinanceCycleMath.inMonth(m.date, of: month) &&
            accounts.contains(where: { $0.id == m.accountID && $0.kind != .loan }) &&
            (m.type == .expense || m.type == .purchase || (m.type == nil && !m.isPayment))
        }
        let totals = Dictionary(grouping: eligible, by: { $0.category }).map { (name: $0.key, total: $0.value.reduce(0) { $0 + $1.amount }) }
        return totals.sorted { $0.total > $1.total }
    }
    /// Linked payment within Card Manager: never count it as new spending or income.
    @discardableResult func payDebt(from debitID: UUID, to debtID: UUID, amount: Double, date: Date = .now, statementID: UUID? = nil) -> Bool {
        guard debitID != debtID, amount.isFinite, amount > 0,
              let sourceIndex = data.accounts.firstIndex(where: { $0.id == debitID && $0.kind == .debit }),
              let targetIndex = data.accounts.firstIndex(where: { $0.id == debtID && $0.kind != .debit }),
              data.accounts[sourceIndex].available + 0.005 >= amount,
              data.accounts[targetIndex].used + 0.005 >= amount else { return false }
        let targetKind = data.accounts[targetIndex].kind
        var linkedIndex: Int? = nil
        if let statementID {
            guard targetKind == .credit,
                  let i = data.statements.firstIndex(where: { $0.id == statementID && $0.accountID == debtID }),
                  data.statements[i].pending + 0.005 >= amount else { return false }
            linkedIndex = i
        }
        let group = UUID()
        let from = FinanceMovement(accountID: debitID, title: "Pago de deuda · \(data.accounts[targetIndex].name)", amount: amount, date: date, type: .transferOut, transferGroupID: group)
        let to = FinanceMovement(accountID: debtID, title: "Pago desde \(data.accounts[sourceIndex].name)", amount: amount, date: date, isPayment: true,
                                 type: targetKind == .credit ? .cardPayment : .loanPayment, transferGroupID: group, linkedStatementID: statementID)
        data.accounts[sourceIndex].used += amount
        data.accounts[targetIndex].used = max(0, data.accounts[targetIndex].used - amount)
        if let i = linkedIndex { data.statements[i].paidAmount = min(data.statements[i].amountToAvoidInterest, data.statements[i].paidAmount + amount) }
        data.movements.append(contentsOf: [from,to]); save(); return true
    }
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
        guard sourceID != targetID, amount.isFinite, amount > 0,
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
        let statementIDs = Set(decoded.statements.map(\.id))
        guard decoded.movements.allSatisfy({ $0.linkedStatementID == nil || statementIDs.contains($0.linkedStatementID!) }) else { throw BackupError.invalidData }
        let planIDs = Set(decoded.plans.map(\.id))
        guard decoded.scheduleOverrides.allSatisfy({ planIDs.contains($0.planID) && $0.amount > 0 && $0.paidAmount >= 0 && $0.paidAmount <= $0.amount }) else { throw BackupError.invalidData }
        guard decoded.statements.allSatisfy({ bill in
            decoded.accounts.contains(where: { $0.id == bill.accountID && $0.kind == .credit }) && bill.amountToAvoidInterest.isFinite && bill.minimumPayment.isFinite && bill.statementBalance.isFinite && bill.statementBalance >= 0 && bill.paidAmount.isFinite && bill.amountToAvoidInterest >= 0 && bill.minimumPayment >= 0 && bill.paidAmount >= 0 && bill.paidAmount <= bill.amountToAvoidInterest + 0.001
        }) else { throw BackupError.invalidData }
        guard decoded.accounts.allSatisfy({ $0.limit.isFinite && $0.used.isFinite && $0.limit >= 0 && $0.used >= 0 }) && decoded.movements.allSatisfy({ $0.amount.isFinite && $0.amount > 0 }) else { throw BackupError.invalidData }
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
    @discardableResult func deleteAccount(_ id: UUID) -> Bool {
        guard data.accounts.contains(where: { $0.id == id }) else { return false }
        let before = data
        let localMovements = data.movements.filter { $0.accountID == id }
        let groups = Set(localMovements.compactMap(\.transferGroupID))
        let legacyPartIDs = Set(localMovements.filter { local in
            data.movements.contains { other in other.id != local.id && legacyTransferPair(local, other) }
        }.map(\.id))
        let legacyParts = localMovements.filter { legacyPartIDs.contains($0.id) }
        let linked = data.movements.filter { movement in
            if let group = movement.transferGroupID, groups.contains(group) { return true }
            return legacyPartIDs.contains(movement.id) || legacyParts.contains { legacyTransferPair($0, movement) }
        }
        for item in linked {
            guard applying(item, multiplier: -1) else { data = before; return false }
            if let billID = item.linkedStatementID {
                guard let index = data.statements.firstIndex(where: { $0.id == billID }),
                      data.statements[index].paidAmount + 0.005 >= item.amount else { data = before; return false }
                data.statements[index].paidAmount = max(0, data.statements[index].paidAmount - item.amount)
            }
        }
        let removedIDs = Set(localMovements.map(\.id)).union(linked.map(\.id))
        data.movements.removeAll { removedIDs.contains($0.id) }
        data.statements.removeAll { $0.accountID == id }
        data.accounts.removeAll { $0.id == id }
        let planIDs = Set(data.plans.filter { $0.accountID == id }.map(\.id))
        data.scheduleOverrides.removeAll { planIDs.contains($0.planID) }
        data.plans.removeAll { $0.accountID == id }
        save(); return true
    }
    private func legacyTransferPair(_ a: FinanceMovement, _ b: FinanceMovement) -> Bool {
        let outgoing = "Transferencia enviada #"
        let incoming = "Transferencia recibida #"
        let isTransfer = (a.title.hasPrefix(outgoing) || a.title.hasPrefix(incoming)) &&
            (b.title.hasPrefix(outgoing) || b.title.hasPrefix(incoming))
        guard isTransfer, let suffixA = a.title.split(separator: "#").last,
              let suffixB = b.title.split(separator: "#").last else { return false }
        return suffixA == suffixB && a.amount == b.amount
    }
    // A single sign convention: positive increases outstanding debt or debit spending.
    // Legacy records without a type keep their original sign semantics.
    func movementEffect(_ movement: FinanceMovement, kind: AccountKind) -> Double {
        FinanceLedgerMath.effect(movement, kind: kind)
    }
    private func applying(_ movement: FinanceMovement, multiplier: Double) -> Bool {
        guard let i = data.accounts.firstIndex(where: { $0.id == movement.accountID }),
              let newUsed = FinanceLedgerMath.adjustedUsed(account: data.accounts[i], movement: movement, multiplier: multiplier) else { return false }
        data.accounts[i].used = newUsed
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
    @discardableResult func deleteMovement(_ id: UUID) -> Bool {
        guard let movement = data.movements.first(where: { $0.id == id }) else { return false }
        let items: [FinanceMovement]
        if let group = movement.transferGroupID {
            items = data.movements.filter { $0.transferGroupID == group }
        } else {
            let paired = data.movements.filter { legacyTransferPair(movement, $0) }
            items = paired.count > 1 ? paired : [movement]
        }
        let before = data
        // Atomic rollback if the historical account balance has been reconciled since this move.
        for item in items {
            guard applying(item, multiplier: -1) else { data = before; return false }
            if let billID = item.linkedStatementID {
                guard let idx = data.statements.firstIndex(where: { $0.id == billID }),
                      data.statements[idx].paidAmount + 0.005 >= item.amount else { data = before; return false }
                data.statements[idx].paidAmount = max(0, data.statements[idx].paidAmount - item.amount)
            }
        }
        let deletedIDs = Set(items.map(\.id))
        data.movements.removeAll { deletedIDs.contains($0.id) }
        save(); return true
    }

    func statementDate(for movement: FinanceMovement, account: FinanceAccount) -> Date {
        if let override = movement.statementOverride { return Calendar.current.startOfDay(for: override) }
        return FinanceCycleMath.statementDate(posting: movement.postingDate ?? movement.date, closingDay: account.closingDay)
    }
    func paymentDueDate(for statement: Date, account: FinanceAccount) -> Date {
        return FinanceCycleMath.paymentDate(statement: statement, paymentDay: account.paymentDay)
    }
    func statementPurchases(accountID: UUID, statement: Date) -> Double {
        guard let account = accounts.first(where: { $0.id == accountID && $0.kind == .credit }) else { return 0 }
        let cal = Calendar.current
        return data.movements.filter { $0.accountID == accountID && cal.isDate(statementDate(for: $0, account: account), inSameDayAs: statement) }
            .filter { $0.type == .purchase || ($0.type == nil && !$0.isPayment) }
            .reduce(0) { $0 + $1.amount }
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
