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
        save()
    }
    func deletePlan(_ id: UUID) { data.plans.removeAll { $0.id == id }; save() }
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
        data.plans.removeAll { $0.accountID == id }
        save()
    }
    func addMovement(_ movement: FinanceMovement) {
        guard let i = data.accounts.firstIndex(where: { $0.id == movement.accountID }) else { return }
        let signed = movement.isPayment ? -movement.amount : movement.amount
        if data.accounts[i].kind == .debit {
            data.accounts[i].used = max(0, data.accounts[i].used + signed)
        } else {
            data.accounts[i].used = max(0, data.accounts[i].used + signed)
        }
        data.movements.append(movement)
        save()
    }
    func deleteMovement(_ id: UUID) {
        guard let m = data.movements.first(where: { $0.id == id }) else { return }
        if let i = data.accounts.firstIndex(where: { $0.id == m.accountID }) {
            let signed = m.isPayment ? -m.amount : m.amount
            data.accounts[i].used = max(0, data.accounts[i].used - signed)
        }
        data.movements.removeAll { $0.id == id }
        save()
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
