import SwiftUI
import Charts

private func money(_ value: Double) -> String {
    value.formatted(.currency(code: "MXN"))
}

struct RootView: View {
    var body: some View {
        TabView {
            PremiumHome().tabItem { Label("Inicio", systemImage: "house.fill") }
            PremiumAccounts().tabItem { Label("Tarjetas", systemImage: "creditcard.fill") }
            PremiumMovements().tabItem { Label("Movimientos", systemImage: "arrow.left.arrow.right") }
            PremiumAnalytics().tabItem { Label("Análisis", systemImage: "chart.bar.fill") }
            PremiumMore().tabItem { Label("Más", systemImage: "ellipsis") }
        }
        .tint(Color.cmGreen)
        .preferredColorScheme(.dark)
    }
}

struct DashboardView: View {
    @EnvironmentObject private var store: FinanceStore
    private let accent = Color(red: 0.63, green: 0.99, blue: 0.30)
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("CARD MANAGER  /  PRO").font(.caption2.bold()).tracking(2.8).foregroundStyle(accent)
                            Text("Tu dinero, bajo control.").font(.title2.bold()).foregroundStyle(.white)
                        }
                        Spacer()
                        Image(systemName: "chart.xyaxis.line").font(.title3).foregroundStyle(accent)
                            .frame(width: 44, height: 44).background(.white.opacity(0.08), in: Circle())
                    }
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 26).fill(LinearGradient(colors: [Color(red: 0.11,green: 0.19,blue: 0.12), Color(red: 0.035,green: 0.055,blue: 0.045)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        MarketBackdrop().opacity(0.36).clipShape(RoundedRectangle(cornerRadius: 26))
                        VStack(alignment: .leading, spacing: 16) {
                            Label("PANORAMA FINANCIERO", systemImage: "circle.grid.cross").font(.caption2.bold()).tracking(1.7).foregroundStyle(accent)
                            Text(money(store.totalLimit - store.totalUsedCredit)).font(.system(size: 35, weight: .bold, design: .rounded)).minimumScaleFactor(0.65).lineLimit(1).foregroundStyle(.white)
                            Text("Crédito disponible").font(.subheadline).foregroundStyle(.white.opacity(0.7))
                            Rectangle().fill(.white.opacity(0.15)).frame(height: 1)
                            HStack {
                                VStack(alignment: .leading, spacing: 5) { Text("DEUDA ACTUAL").font(.caption2).foregroundStyle(.white.opacity(0.6)); Text(money(store.totalDebt)).font(.headline).foregroundStyle(.white) }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 5) { Text("LÍMITE TOTAL").font(.caption2).foregroundStyle(.white.opacity(0.6)); Text(money(store.totalLimit)).font(.headline).foregroundStyle(accent) }
                            }
                        }.padding(24)
                    }.frame(height: 240)
                    let ratio = store.totalLimit > 0 ? store.totalUsedCredit / store.totalLimit : 0
                    VStack(alignment: .leading, spacing: 12) {
                        HStack { Text("Salud de tu crédito").font(.headline); Spacer(); Text(ratio.formatted(.percent.precision(.fractionLength(0)))).font(.headline).foregroundStyle(ratio > 0.5 ? .orange : accent) }
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                Capsule().fill(.white.opacity(0.10))
                                Capsule().fill(ratio > 0.5 ? Color.orange : accent).frame(width: g.size.width * min(1, max(0, ratio)))
                            }
                        }.frame(height: 9)
                        Text(ratio <= 0.3 ? "Uso dentro de la referencia del 30%." : "Puedes reducir tu porcentaje de utilización.").font(.caption).foregroundStyle(.white.opacity(0.55))
                    }.padding(20).background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 22))
                    HStack { Text("Tus tarjetas").font(.title3.bold()); Spacer(); Text("\(store.accounts.count) activas").font(.caption).foregroundStyle(.secondary) }
                    if let first = store.accounts.first { WalletCard(account: first) }
                    else { Text("Agrega tu primera tarjeta desde Tarjetas.").foregroundStyle(.secondary).padding() }
                    HStack { Text("Próximos pagos").font(.title3.bold()); Spacer(); Image(systemName: "calendar").foregroundStyle(accent) }
                    ForEach(store.accounts.filter { $0.kind != .debit }) { a in
                        HStack(spacing: 14) {
                            Image(systemName: "calendar.badge.clock").foregroundStyle(accent).frame(width: 40, height: 40).background(accent.opacity(0.09), in: RoundedRectangle(cornerRadius: 12))
                            VStack(alignment: .leading, spacing: 4) { Text(a.name).font(.subheadline.bold()); Text("Fecha de pago: día \(a.paymentDay)").font(.caption).foregroundStyle(.secondary) }
                            Spacer()
                            Text(money(a.used)).font(.subheadline.bold())
                        }.padding(13).background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 17))
                    }
                    Text("Los datos bursátiles de fondo son ilustrativos.").font(.caption2).foregroundStyle(.secondary)
                }.padding(18)
            }
            .background(Color(red: 0.035,green: 0.045,blue: 0.04).ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
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
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            LabeledContent("Tipo", value: account.kind.rawValue)
                            LabeledContent("Banco", value: BankCatalog.name(for: account.bankID))
                            LabeledContent("Red", value: account.network)
                            LabeledContent("Límite / saldo inicial", value: money(account.limit))
                            LabeledContent("Usado", value: money(account.used))
                            LabeledContent("Disponible", value: money(account.available))
                            LabeledContent("Corte", value: "Día \(account.closingDay)")
                            LabeledContent("Pago", value: "Día \(account.paymentDay)")
                        }.padding(16).background(Color.cmPanel, in: RoundedRectangle(cornerRadius: 16))
                        AccountPlansSection(account: account)
                        Text("Movimientos").font(.headline)
                        ForEach(store.movements.filter { $0.accountID == accountID }) { m in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(m.title)
                                    Text(m.date, style: .date).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("\(m.isPayment ? "−" : "+")\(money(m.amount))")
                            }.padding(12).background(Color.cmPanel, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }.padding(16)
                }
                .background(Color.cmBackground.ignoresSafeArea())
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
                TextField(kind == .debit ? "Saldo de débito" : "Límite / monto original", text: $limit).keyboardType(.decimalPad)
                TextField(kind == .debit ? "Ajuste del saldo (normalmente 0)" : "Monto utilizado / deuda", text: $used).keyboardType(.decimalPad)
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
                TextField(kind == .debit ? "Saldo de débito" : "Límite / monto original", text: $limit).keyboardType(.decimalPad)
                TextField(kind == .debit ? "Ajuste del saldo (normalmente 0)" : "Monto utilizado / deuda", text: $used).keyboardType(.decimalPad)
                Stepper("Día de corte: \(closingDay)", value: $closingDay, in: 1...31)
                Stepper("Día de pago: \(paymentDay)", value: $paymentDay, in: 1...31)
                Text("Para débito, escribe tu saldo actual y deja el ajuste en 0. El saldo mostrado es saldo menos ajuste. Los días 29–31 pueden no existir en todos los meses.").font(.caption).foregroundStyle(.secondary)
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
                Toggle("Pago / ingreso (aumenta saldo en débito)", isOn: $isPayment)
                Text("En crédito y préstamos: pago reduce deuda, cargo la aumenta. En débito: ingreso aumenta tu saldo y gasto lo reduce. No registres una transferencia entre cuentas propias como ingreso nuevo.").font(.caption).foregroundStyle(.secondary)
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
