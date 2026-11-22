import SwiftUI
import Charts

private func money(_ value: Double) -> String {
    value.formatted(.currency(code: "MXN"))
}

struct RootView: View {
    var body: some View {
        TabView {
            DashboardView().tabItem { Label("Inicio", systemImage: "house.fill") }
            AccountsView().tabItem { Label("Tarjetas", systemImage: "creditcard.fill") }
            WalletView().tabItem { Label("Wallet", systemImage: "square.stack.fill") }
            MovementsView().tabItem { Label("Movimientos", systemImage: "arrow.left.arrow.right") }
            InsightsView().tabItem { Label("Análisis", systemImage: "chart.bar.fill") }
        }
        .tint(.green)
    }
}

struct DashboardView: View {
    @EnvironmentObject private var store: FinanceStore
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Tu panorama financiero").font(.headline)
                    HStack(spacing: 12) {
                        SummaryCard(title: "Deuda total", value: money(store.totalDebt), symbol: "chart.line.downtrend.xyaxis")
                        SummaryCard(title: "Crédito disponible", value: money(max(0, store.totalLimit - store.totalUsedCredit)), symbol: "checkmark.circle")
                    }
                    let ratio = store.totalLimit > 0 ? store.totalUsedCredit / store.totalLimit : 0
                    VStack(alignment: .leading, spacing: 8) {
                        HStack { Text("Uso de crédito"); Spacer(); Text(ratio.formatted(.percent.precision(.fractionLength(1)))) }
                        ProgressView(value: min(1, ratio)).tint(ratio > 0.5 ? .orange : .green)
                        Text(ratio <= 0.3 ? "Dentro de tu objetivo de 30%" : "Referencia: procura mantener el uso bajo 30% cuando sea posible")
                            .font(.caption).foregroundStyle(.secondary)
                    }.padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    MarketBackdrop().frame(height: 72).clipped().cornerRadius(14)
                    Text("Próximos días de pago").font(.headline)
                    ForEach(store.accounts.filter { $0.kind != .debit }) { a in
                        HStack { Text(a.name); Spacer(); Text("Día \(a.paymentDay)").foregroundStyle(.secondary) }
                            .padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    if store.accounts.isEmpty { ContentUnavailableView("Agrega tu primera tarjeta", systemImage: "creditcard", description: Text("Empieza en la pestaña Tarjetas.")) }
                }.padding()
            }.navigationTitle("Card Manager")
        }
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let symbol: String
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: symbol).foregroundStyle(.green)
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.headline).minimumScaleFactor(0.65).lineLimit(1)
        }.frame(maxWidth: .infinity, alignment: .leading).padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct AccountsView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var adding = false
    @State private var pendingDeletion: FinanceAccount?
    var body: some View {
        NavigationStack {
            List {
                ForEach(store.accounts) { account in
                    NavigationLink {
                        AccountDetailView(accountID: account.id)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack { Text(account.name).font(.headline); Spacer(); Text(account.kind.rawValue).font(.caption).foregroundStyle(.secondary) }
                            Text("Usado: \(money(account.used))")
                            Text("Disponible: \(money(account.available))").font(.caption)
                            if account.kind == .credit { ProgressView(value: min(1, account.utilization)).tint(account.utilization > 0.5 ? .orange : .green) }
                        }.padding(.vertical, 6)
                    }
                }.onDelete { offsets in
                    if let index = offsets.first { pendingDeletion = store.accounts[index] }
                }
            }
            .confirmationDialog("¿Eliminar tarjeta?", isPresented: Binding(get: { pendingDeletion != nil }, set: { if !$0 { pendingDeletion = nil } }), titleVisibility: .visible) {
                Button("Eliminar tarjeta y movimientos", role: .destructive) {
                    if let account = pendingDeletion { store.deleteAccount(account.id) }
                    pendingDeletion = nil
                }
                Button("Cancelar", role: .cancel) { pendingDeletion = nil }
            } message: { Text("Esta acción también eliminará los movimientos de la tarjeta.") }
            .navigationTitle("Mis tarjetas")
            .toolbar { Button("Agregar", systemImage: "plus") { adding = true } }
            .sheet(isPresented: $adding) { AddAccountView() }
            .overlay { if store.accounts.isEmpty { ContentUnavailableView("Sin cuentas", systemImage: "creditcard", description: Text("Agrega una tarjeta o préstamo.")) } }
        }
    }
}

struct AccountDetailView: View {
    @EnvironmentObject private var store: FinanceStore
    let accountID: UUID
    @State private var editing = false
    var body: some View {
        Group {
            if let account = store.accounts.first(where: { $0.id == accountID }) {
                List {
                    LabeledContent("Tipo", value: account.kind.rawValue)
                    LabeledContent("Banco", value: BankCatalog.name(for: account.bankID))
                    LabeledContent("Red", value: account.network)
                    LabeledContent("Límite / saldo inicial", value: money(account.limit))
                    LabeledContent("Usado", value: money(account.used))
                    LabeledContent("Disponible", value: money(account.available))
                    LabeledContent("Corte", value: "Día \(account.closingDay)")
                    LabeledContent("Pago", value: "Día \(account.paymentDay)")
                    Section("Movimientos") {
                        ForEach(store.movements.filter { $0.accountID == accountID }) { m in
                            HStack { VStack(alignment: .leading) { Text(m.title); Text(m.date, style: .date).font(.caption).foregroundStyle(.secondary) }; Spacer(); Text("\(m.isPayment ? "−" : "+")\(money(m.amount))") }
                        }
                    }
                }
                .navigationTitle(account.name)
                .toolbar { Button("Editar") { editing = true } }
                .sheet(isPresented: $editing) { EditAccountView(account: account) }
            } else { ContentUnavailableView("Cuenta no encontrada", systemImage: "exclamationmark.circle") }
        }
    }
}

struct EditAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: FinanceStore
    let account: FinanceAccount
    @State private var name: String
    @State private var kind: AccountKind
    @State private var limit: String
    @State private var used: String
    @State private var closingDay: Int
    @State private var paymentDay: Int
    @State private var bankID: String
    @State private var network: String

    init(account: FinanceAccount) {
        self.account = account
        _name = State(initialValue: account.name)
        _kind = State(initialValue: account.kind)
        _limit = State(initialValue: String(account.limit))
        _used = State(initialValue: String(account.used))
        _closingDay = State(initialValue: account.closingDay)
        _paymentDay = State(initialValue: account.paymentDay)
        _bankID = State(initialValue: account.bankID)
        _network = State(initialValue: account.network)
    }

    private func number(_ value: String) -> Double? {
        Double(value.replacingOccurrences(of: ",", with: "."))
    }

    var body: some View {
        NavigationStack {
            Form {
                BankSelector(selection: $bankID)
                Picker("Red", selection: $network) { ForEach(CardNetworks.names, id: \.self) { Text($0).tag($0) } }
                TextField("Nombre", text: $name)
                Picker("Tipo", selection: $kind) {
                    ForEach(AccountKind.allCases) { Text($0.rawValue).tag($0) }
                }
                TextField("Límite o saldo inicial", text: $limit).keyboardType(.decimalPad)
                TextField("Monto utilizado / deuda", text: $used).keyboardType(.decimalPad)
                Stepper("Día de corte: \(closingDay)", value: $closingDay, in: 1...31)
                Stepper("Día de pago: \(paymentDay)", value: $paymentDay, in: 1...31)
                Text("Corregir el monto utilizado no altera el historial de movimientos.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .navigationTitle("Editar tarjeta")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        guard let newLimit = number(limit), let newUsed = number(used) else { return }
                        var updated = account
                        updated.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        updated.kind = kind
                        updated.limit = newLimit
                        updated.used = newUsed
                        updated.closingDay = closingDay
                        updated.paymentDay = paymentDay
                        updated.bankID = bankID
                        updated.network = network
                        store.updateAccount(updated)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                              number(limit) == nil || number(used) == nil ||
                              (number(limit) ?? -1) < 0 || (number(used) ?? -1) < 0)
                }
            }
        }
    }
}

struct AddAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: FinanceStore
    @State private var name = ""
    @State private var kind: AccountKind = .credit
    @State private var limit = ""
    @State private var used = ""
    @State private var closingDay = 1
    @State private var paymentDay = 20
    @State private var bankID = ""
    @State private var network = "Sin especificar"
    var body: some View {
        NavigationStack {
            Form {
                BankSelector(selection: $bankID)
                Picker("Red", selection: $network) { ForEach(CardNetworks.names, id: \.self) { Text($0).tag($0) } }
                TextField("Nombre (ej. Nu)", text: $name)
                Picker("Tipo", selection: $kind) { ForEach(AccountKind.allCases) { Text($0.rawValue).tag($0) } }
                TextField("Límite o saldo inicial", text: $limit).keyboardType(.decimalPad)
                TextField("Monto utilizado / deuda", text: $used).keyboardType(.decimalPad)
                Stepper("Día de corte: \(closingDay)", value: $closingDay, in: 1...31)
                Stepper("Día de pago: \(paymentDay)", value: $paymentDay, in: 1...31)
                Text("Para débito, registra el saldo en el campo de límite. Los días 29–31 pueden no existir en todos los meses.").font(.caption).foregroundStyle(.secondary)
            }
            .navigationTitle("Nueva cuenta")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        store.addAccount(FinanceAccount(name: name.trimmingCharacters(in: .whitespacesAndNewlines), kind: kind, limit: max(0, Double(limit.replacingOccurrences(of: ",", with: ".")) ?? 0), used: max(0, Double(used.replacingOccurrences(of: ",", with: ".")) ?? 0), closingDay: closingDay, paymentDay: paymentDay, bankID: bankID, network: network))
                        dismiss()
                    }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

struct MovementsView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var adding = false
    var body: some View {
        NavigationStack {
            List {
                ForEach(store.movements) { m in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(m.title).font(.headline)
                            Text(store.accounts.first(where: { $0.id == m.accountID })?.name ?? "Cuenta eliminada")
                                .font(.caption).foregroundStyle(.secondary)
                            Text(m.date, style: .date).font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(m.isPayment ? "−" : "+")\(money(m.amount))")
                    }
                }.onDelete { offsets in
                    for i in offsets { store.deleteMovement(store.movements[i].id) }
                }
            }
            .navigationTitle("Movimientos")
            .toolbar { Button("Agregar", systemImage: "plus") { adding = true }.disabled(store.accounts.isEmpty) }
            .sheet(isPresented: $adding) { AddMovementView() }
            .overlay { if store.movements.isEmpty { ContentUnavailableView("Sin movimientos", systemImage: "arrow.left.arrow.right", description: Text("Registra compras o abonos.")) } }
        }
    }
}

struct AddMovementView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss
    @State private var accountID: UUID?
    @State private var title = ""
    @State private var amount = ""
    @State private var date = Date()
    @State private var isPayment = false
    var body: some View {
        NavigationStack {
            Form {
                Picker("Cuenta", selection: $accountID) {
                    Text("Selecciona").tag(UUID?.none)
                    ForEach(store.accounts) { a in Text(a.name).tag(Optional(a.id)) }
                }
                TextField("Concepto", text: $title)
                TextField("Monto", text: $amount).keyboardType(.decimalPad)
                DatePicker("Fecha", selection: $date, displayedComponents: .date)
                Toggle("Es abono / pago", isOn: $isPayment)
                Text("Los abonos disminuyen el saldo utilizado; los cargos lo aumentan.").font(.caption).foregroundStyle(.secondary)
            }
            .navigationTitle("Nuevo movimiento")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        guard let accountID else { return }
                        store.addMovement(FinanceMovement(accountID: accountID, title: title, amount: Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0, date: date, isPayment: isPayment))
                        dismiss()
                    }.disabled(accountID == nil || title.isEmpty || (Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0) <= 0)
                }
            }
        }
    }
}

struct InsightsView: View {
    @EnvironmentObject private var store: FinanceStore
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("Deuda por cuenta").font(.headline)
                    if store.accounts.isEmpty {
                        ContentUnavailableView("Sin datos", systemImage: "chart.bar", description: Text("Agrega cuentas para ver las gráficas."))
                    } else {
                        Chart(store.accounts.filter { $0.kind != .debit }) { a in
                            BarMark(x: .value("Cuenta", a.name), y: .value("Deuda", a.used))
                                .foregroundStyle(.green.gradient)
                        }.frame(height: 230)
                        Text("Utilización de tarjetas").font(.headline)
                        Chart(store.accounts.filter { $0.kind == .credit }) { a in
                            BarMark(x: .value("Cuenta", a.name), y: .value("Porcentaje", a.utilization * 100))
                                .foregroundStyle(a.utilization > 0.5 ? .orange : .green)
                        }.frame(height: 230)
                        Text("Las gráficas reflejan los saldos que registras manualmente, no datos bancarios en tiempo real.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }.padding()
            }.navigationTitle("Análisis")
        }
    }
}
