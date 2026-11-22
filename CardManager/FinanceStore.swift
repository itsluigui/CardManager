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
    var movements: [FinanceMovement] { data.movements.sorted { $0.date > $1.date } }
    var totalDebt: Double { data.accounts.filter { $0.kind != .debit }.reduce(0) { $0 + $1.used } }
    var totalLimit: Double { data.accounts.filter { $0.kind == .credit }.reduce(0) { $0 + $1.limit } }
    var totalUsedCredit: Double { data.accounts.filter { $0.kind == .credit }.reduce(0) { $0 + $1.used } }

    func addAccount(_ account: FinanceAccount) { data.accounts.append(account); save() }
    func deleteAccount(_ id: UUID) {
        data.accounts.removeAll { $0.id == id }
        data.movements.removeAll { $0.accountID == id }
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
