import SwiftUI
import Charts

// MARK: - Studio design language
private enum Studio {
    static let green = Color.cmGreen
    static let muted = Color(red: 0.56, green: 0.62, blue: 0.59)
    static let amber = Color(red: 0.98, green: 0.73, blue: 0.31)
    static let red = Color(red: 0.99, green: 0.46, blue: 0.40)
    static let blue = Color(red: 0.43, green: 0.65, blue: 1)
    static func money(_ value: Double) -> String { value.formatted(.currency(code: "MXN")) }
    static func month(_ date: Date) -> String { date.formatted(.dateTime.month(.wide).year()).capitalized }
}

private struct StudioSurface<Content: View>: View {
    var glow: Bool = false
    let content: Content
    init(glow: Bool = false, @ViewBuilder content: () -> Content) {
        self.glow = glow
        self.content = content()
    }
    var body: some View {
        content.padding(17).frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 23, style: .continuous)
                    .fill(glow ? LinearGradient(colors: [Color(red: 0.09, green: 0.21, blue: 0.14), Color.cmPanel], startPoint: .topLeading, endPoint: .bottomTrailing) : LinearGradient(colors: [Color.cmPanel, Color.cmPanel], startPoint: .top, endPoint: .bottom))
            }
            .overlay(RoundedRectangle(cornerRadius: 23, style: .continuous).stroke(.white.opacity(glow ? 0.14 : 0.075), lineWidth: 1))
    }
}

private struct StudioHeading: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(eyebrow.uppercased()).font(.system(size: 10, weight: .heavy, design: .rounded)).tracking(2.2).foregroundStyle(Studio.green)
            Text(title).font(.system(size: 29, weight: .bold, design: .rounded)).foregroundStyle(.white)
            Text(subtitle).font(.caption).foregroundStyle(Studio.muted)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(.top, 10)
    }
}

private struct StudioMetric: View {
    let icon: String
    let title: String
    let amount: Double
    var accent: Color = .white
    var body: some View {
        StudioSurface {
            VStack(alignment: .leading, spacing: 9) {
                Label(title, systemImage: icon).font(.system(size: 11, weight: .medium)).foregroundStyle(Studio.muted)
                    .lineLimit(1).minimumScaleFactor(0.8)
                Text(Studio.money(amount)).font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(accent).monospacedDigit().lineLimit(1).minimumScaleFactor(0.57)
            }
        }
    }
}

private struct StudioProgress: View {
    let value: Double
    var color: Color = .cmGreen
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.12))
                Capsule().fill(color).frame(width: max(0, proxy.size.width * min(1,max(0,value))))
            }
        }.frame(height: 8).accessibilityLabel("Progreso \(Int(value * 100)) por ciento")
    }
}

private struct StudioMonthSelector: View {
    @Binding var month: Date
    var body: some View {
        HStack(spacing: 12) {
            Button { shift(-1) } label: { Image(systemName: "chevron.left").frame(width: 32, height: 32) }
                .accessibilityLabel("Mes anterior")
            Text(Studio.month(month)).font(.subheadline.bold()).frame(maxWidth: .infinity)
            Button { shift(1) } label: { Image(systemName: "chevron.right").frame(width: 32, height: 32) }
                .accessibilityLabel("Mes siguiente")
        }.foregroundStyle(.white).padding(6).background(Color.cmPanel, in: Capsule())
    }
    private func shift(_ n: Int) {
        let start = FinanceCycleMath.monthStart(month)
        month = Calendar.current.date(byAdding: .month, value: n, to: start) ?? start
    }
}

private struct StudioAccountRow: View {
    let account: FinanceAccount
    var body: some View {
        HStack(spacing: 12) {
            CMBrandBadge(account: account, size: 44)
            VStack(alignment: .leading, spacing: 5) {
                Text(account.name).font(.subheadline.bold()).foregroundStyle(.white).lineLimit(1)
                Text(account.kind == .debit ? "Dinero disponible" : (account.kind == .loan ? "Deuda pendiente" : "Saldo utilizado"))
                    .font(.caption2).foregroundStyle(Studio.muted)
            }
            Spacer(minLength: 6)
            VStack(alignment: .trailing, spacing: 5) {
                Text(Studio.money(account.kind == .debit ? account.available : account.used))
                    .font(.subheadline.bold()).foregroundStyle(account.kind == .debit ? Studio.green : .white)
                    .lineLimit(1).minimumScaleFactor(0.65)
                if account.kind == .credit { Text((account.utilization).formatted(.percent.precision(.fractionLength(1)))).font(.caption2).foregroundStyle(creditTone(account.utilization)) }
            }
            Image(systemName: "chevron.right").font(.caption2).foregroundStyle(Studio.muted)
        }.padding(14).background(Color.cmPanel, in: RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - Monthly obligations: confirmed statements are never inferred from account debt.
struct StudioHome: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var month = Date()
    private var overview: MonthOverview { store.monthOverview(for: month) }
    private var utilization: Double { store.creditUtilization }
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 17) {
                    HStack(alignment: .top) {
                        StudioHeading(eyebrow: "Tu espacio financiero", title: "Card Manager Pro", subtitle: "Todo en orden, a tu manera")
                        Image(systemName: "circle.hexagongrid.fill").font(.title2).foregroundStyle(Studio.green)
                            .frame(width: 45, height: 45).background(Studio.green.opacity(0.10), in: Circle()).padding(.top, 11)
                    }
                    StudioSurface(glow: true) {
                        VStack(alignment: .leading, spacing: 16) {
                            Label("DEUDA TOTAL REGISTRADA", systemImage: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 11, weight: .bold)).tracking(1).foregroundStyle(.white.opacity(0.67))
                            Text(Studio.money(store.totalDebt))
                                .font(.system(size: 35, weight: .bold, design: .rounded)).monospacedDigit()
                                .minimumScaleFactor(0.6).lineLimit(1)
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Crédito utilizado").font(.caption2).foregroundStyle(Studio.muted)
                                    Text(Studio.money(store.totalUsedCredit)).font(.subheadline.bold())
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Préstamos pendientes").font(.caption2).foregroundStyle(Studio.muted)
                                    Text(Studio.money(store.totalLoanDebt)).font(.subheadline.bold())
                                }
                            }
                        }
                    }
                    NavigationLink(destination: StudioMonthPlan(initialMonth: month)) {
                        StudioSurface {
                            VStack(alignment: .leading, spacing: 11) {
                                HStack {
                                    Label("A pagar en el mes", systemImage: "calendar.badge.clock").font(.headline)
                                    Spacer()
                                    Image(systemName: "arrow.up.right").foregroundStyle(Studio.green)
                                }
                                Text(Studio.month(month)).font(.caption).foregroundStyle(Studio.muted)
                                Text(Studio.money(overview.combinedKnownTotal))
                                    .font(.system(size: 29, weight: .bold, design: .rounded)).foregroundStyle(Studio.green)
                                    .monospacedDigit().minimumScaleFactor(0.6).lineLimit(1)
                                HStack {
                                    Text("Tarjetas confirmadas: \(Studio.money(overview.confirmedCardTotal))")
                                    Spacer(minLength: 4)
                                }.font(.caption2).foregroundStyle(Studio.muted)
                                Text("Préstamos programados: \(Studio.money(overview.scheduledLoanTotal))").font(.caption2).foregroundStyle(Studio.muted)
                                if overview.hasUnknownAmounts {
                                    Label("Faltan estados de cuenta: este total es parcial", systemImage: "exclamationmark.circle")
                                        .font(.caption2.bold()).foregroundStyle(Studio.amber)
                                } else if overview.obligations.isEmpty {
                                    Text("No hay importes exigibles confirmados o programados.").font(.caption2).foregroundStyle(Studio.muted)
                                }
                            }
                        }
                    }.buttonStyle(.plain)
                    StudioMonthSelector(month: $month)
                    HStack(spacing: 10) {
                        NavigationLink(destination: StudioDebit()) {
                            StudioMetric(icon: "banknote", title: "Mi dinero", amount: store.debitBalance, accent: Studio.green)
                        }.buttonStyle(.plain)
                        StudioMetric(icon: "creditcard", title: "Crédito libre", amount: store.availableCredit)
                    }
                    StudioSurface {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Label("Utilización de crédito", systemImage: "gauge.with.dots.needle.33percent").font(.subheadline.bold())
                                Spacer()
                                Text(utilization.formatted(.percent.precision(.fractionLength(1))))
                                    .font(.headline.bold()).foregroundStyle(creditTone(utilization))
                            }
                            StudioProgress(value: utilization, color: creditTone(utilization))
                            HStack {
                                Text("Referencia orientativa: 30 %")
                                Spacer()
                                Text("Límite: \(Studio.money(store.totalLimit))")
                            }.font(.caption2).foregroundStyle(Studio.muted)
                            if store.amountToTarget > 0 && store.totalLimit > 0 {
                                Text("Para llegar al 30 % de uso: reducir cerca de \(Studio.money(store.amountToTarget)).")
                                    .font(.caption).foregroundStyle(Studio.amber)
                            }
                        }
                    }
                    StudioSurface {
                        VStack(alignment: .leading, spacing: 11) {
                            HStack { Label("Cobertura del mes", systemImage: "shield.lefthalf.filled").font(.subheadline.bold()); Spacer(); NavigationLink("Ver pagos", destination: StudioMonthPlan(initialMonth: month)).font(.caption.bold()).foregroundStyle(Studio.green) }
                            let known = overview.combinedKnownTotal
                            if known > 0 {
                                StudioProgress(value: store.debitBalance / known, color: store.debitBalance >= known ? Studio.green : Studio.amber)
                                Text("Tu dinero registrado cubre \(Int(min(999, max(0,store.debitBalance / known * 100)))) % de los importes conocidos de este mes.")
                                    .font(.caption).foregroundStyle(Studio.muted)
                            } else { Text("Agrega importes de estados de cuenta o planes para calcular cobertura.").font(.caption).foregroundStyle(Studio.muted) }
                            Text("Es una comparación de saldos, no una predicción de ingresos ni una calificación financiera.")
                                .font(.caption2).foregroundStyle(Studio.muted)
                        }
                    }
                    HStack {
                        Text("Mis tarjetas").font(.title3.bold())
                        Spacer()
                        Text("\(store.accounts.filter { $0.kind != .loan }.count) registradas").font(.caption).foregroundStyle(Studio.muted)
                    }
                    let cards = store.accounts.filter { $0.kind != .loan }
                    if cards.isEmpty { StudioSurface { Text("Agrega una tarjeta desde la pestaña Tarjetas.").foregroundStyle(Studio.muted) } }
                    else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 13) {
                                ForEach(cards) { a in
                                    NavigationLink(destination: AccountDetailView(accountID: a.id)) {
                                        CMCardFace(account: a, compact: true).frame(width: 258)
                                    }.buttonStyle(.plain)
                                }
                            }.padding(.vertical, 8).padding(.horizontal, 2)
                        }
                    }
                    HStack {
                        Text("Actividad reciente").font(.title3.bold())
                        Spacer()
                        Text("Registro manual").font(.caption2).foregroundStyle(Studio.muted)
                    }
                    ForEach(store.movements.prefix(4)) { m in StudioMovementRow(movement: m) }
                    Text("Los saldos no están sincronizados con bancos. Confirma cada pago en su institución.")
                        .font(.caption2).foregroundStyle(Studio.muted)
                }.padding(.horizontal, 18).padding(.bottom, 135)
            }.background(Color.cmBackground.ignoresSafeArea()).toolbar(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - Month planner
struct StudioMonthPlan: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var month: Date
    init(initialMonth: Date = .now) { _month = State(initialValue: initialMonth) }
    @State private var editAccount: FinanceAccount?
    private var overview: MonthOverview { store.monthOverview(for: month) }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                StudioHeading(eyebrow: "Planeación", title: "Pagos del mes", subtitle: "Elige el periodo y revisa cada obligación")
                StudioMonthSelector(month: $month)
                StudioSurface(glow: true) {
                    VStack(alignment: .leading, spacing: 9) {
                        Text("TOTAL CONOCIDO").font(.caption2.bold()).foregroundStyle(Studio.muted)
                        Text(Studio.money(overview.combinedKnownTotal)).font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(Studio.green).lineLimit(1).minimumScaleFactor(0.6)
                        HStack { Text("Crédito confirmado"); Spacer(); Text(Studio.money(overview.confirmedCardTotal)) }
                        HStack { Text("Préstamos previstos"); Spacer(); Text(Studio.money(overview.scheduledLoanTotal)) }
                        Text("No suma MSI a los pagos de tarjeta, para evitar duplicarlos.")
                            .font(.caption2).foregroundStyle(Studio.muted)
                    }.font(.subheadline)
                }
                if overview.hasUnknownAmounts {
                    StudioSurface {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Importes que aún faltan", systemImage: "exclamationmark.triangle.fill")
                                .font(.headline).foregroundStyle(Studio.amber)
                            Text("Solo aparecen productos del mes actual cuyo importe todavía no está confirmado o que aún no tienen calendario suficiente para calcular el vencimiento.")
                                .font(.caption).foregroundStyle(Studio.muted)
                            ForEach(overview.missingItems) { item in
                                if item.kind == .missingLoanSchedule, let loan = store.accounts.first(where: { $0.id == item.accountID }) {
                                    NavigationLink(destination: AccountDetailView(accountID: loan.id)) {
                                        HStack(spacing: 10) {
                                            CMBrandBadge(account: loan, size: 35)
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(item.title)
                                                Text(item.detail).font(.caption2).foregroundStyle(Studio.muted)
                                            }
                                            Spacer()
                                            Text(item.actionLabel).font(.caption).foregroundStyle(Studio.green)
                                            Image(systemName: "chevron.right")
                                        }
                                    }.buttonStyle(.plain).padding(.vertical, 5)
                                } else if let card = store.accounts.first(where: { $0.id == item.accountID }) {
                                    Button { editAccount = card } label: {
                                        HStack(spacing: 10) {
                                            CMBrandBadge(account: card, size: 35)
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(item.title)
                                                Text(item.detail).font(.caption2).foregroundStyle(Studio.muted)
                                            }
                                            Spacer()
                                            Text(item.actionLabel).font(.caption).foregroundStyle(Studio.green)
                                            Image(systemName: "chevron.right")
                                        }
                                    }.buttonStyle(.plain).padding(.vertical, 5)
                                }
                            }
                        }
                    }
                }
                if !overview.futureItems.isEmpty {
                    StudioSurface {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Ya registrados para después", systemImage: "calendar.badge.checkmark")
                                .font(.headline).foregroundStyle(Studio.blue)
                            Text("Estos productos ya tienen una fecha futura registrada y no cuentan como faltantes del mes actual.")
                                .font(.caption).foregroundStyle(Studio.muted)
                            ForEach(overview.futureItems) { item in
                                if item.kind == .nextLoanInstallment, let loan = store.accounts.first(where: { $0.id == item.accountID }) {
                                    NavigationLink(destination: AccountDetailView(accountID: loan.id)) {
                                        HStack(spacing: 10) {
                                            CMBrandBadge(account: loan, size: 35)
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(item.title)
                                                Text(item.detail).font(.caption2).foregroundStyle(Studio.muted)
                                            }
                                            Spacer()
                                            Text(item.actionLabel).font(.caption).foregroundStyle(Studio.green)
                                            Image(systemName: "chevron.right")
                                        }
                                    }.buttonStyle(.plain).padding(.vertical, 5)
                                } else if let card = store.accounts.first(where: { $0.id == item.accountID }) {
                                    Button { editAccount = card } label: {
                                        HStack(spacing: 10) {
                                            CMBrandBadge(account: card, size: 35)
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(item.title)
                                                Text(item.detail).font(.caption2).foregroundStyle(Studio.muted)
                                            }
                                            Spacer()
                                            Text(item.actionLabel).font(.caption).foregroundStyle(Studio.green)
                                            Image(systemName: "chevron.right")
                                        }
                                    }.buttonStyle(.plain).padding(.vertical, 5)
                                }
                            }
                        }
                    }
                }
                if overview.obligations.isEmpty { StudioSurface { Text("Todavía no hay obligaciones confirmadas o cuotas programadas para este mes.").foregroundStyle(Studio.muted) } }
                else {
                    Text("Obligaciones y vencimientos").font(.title3.bold())
                    ForEach(overview.obligations) { item in
                        StudioSurface {
                            HStack(spacing: 12) {
                                Image(systemName: item.isCard ? "creditcard.fill" : "calendar.badge.clock")
                                    .foregroundStyle(item.isCard ? Studio.green : Studio.blue)
                                    .frame(width: 37, height: 37).background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.title).font(.subheadline.bold())
                                    Text(item.subtitle).font(.caption2).foregroundStyle(Studio.muted)
                                    Text(item.dueDate.formatted(date: .abbreviated, time: .omitted)).font(.caption2).foregroundStyle(Studio.muted)
                                }
                                Spacer()
                                Text(Studio.money(item.amount)).font(.subheadline.bold()).minimumScaleFactor(0.6).lineLimit(1)
                            }
                        }
                    }
                }
                StudioSurface {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("MSI informativos del mes").font(.headline)
                        Text(Studio.money(overview.informationalMSI)).font(.title3.bold()).foregroundStyle(Studio.blue)
                        Text("Son cuotas programadas. No las sumamos de nuevo si pertenecen a una tarjeta de crédito; confirma qué mensualidades incluye el estado de cuenta.")
                            .font(.caption).foregroundStyle(Studio.muted)
                    }
                }
                Text("Los vencimientos de cuotas son los registrados. Los importes de tarjetas son solo los que capturaste del estado de cuenta; valida fechas e intereses con el banco.")
                    .font(.caption2).foregroundStyle(Studio.muted)
            }.padding(18).padding(.bottom, 95)
        }.background(Color.cmBackground.ignoresSafeArea()).navigationTitle("Planeador mensual").navigationBarTitleDisplayMode(.inline)
            .sheet(item: $editAccount) { StudioStatementEditor(accountID: $0.id, month: month) }
    }
}

// MARK: - Statement capture (not guessed from total card balance)
struct StudioStatementEditor: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss
    let accountID: UUID
    var month: Date = .now
    @State private var closing = Date()
    @State private var due = Date()
    @State private var toAvoid = ""
    @State private var totalAtCut = ""
    @State private var minimum = ""
    @State private var paid = "0"
    @State private var notes = ""
    @State private var recordID = UUID()
    @State private var error = false
    private var account: FinanceAccount? { store.creditAccounts.first { $0.id == accountID } }
    private func number(_ input: String) -> Double? { Double(input.replacingOccurrences(of: ",", with: ".")) }
    private var valid: Bool {
        guard let total = number(toAvoid), let cutBalance = number(totalAtCut), let min = number(minimum), let done = number(paid) else { return false }
        return total.isFinite && cutBalance.isFinite && min.isFinite && done.isFinite && total >= 0 && cutBalance >= 0 && min >= 0 && done >= 0 && done <= total && due >= closing
    }
    var body: some View {
        NavigationStack {
            Form {
                Section("Estado de cuenta oficial") {
                    Text(account?.name ?? "Tarjeta").font(.headline)
                    DatePicker("Fecha de corte", selection: $closing, displayedComponents: .date)
                    DatePicker("Fecha límite de pago", selection: $due, displayedComponents: .date)
                    TextField("Saldo total al corte", text: $totalAtCut).keyboardType(.decimalPad)
                    TextField("Pago para no generar intereses", text: $toAvoid).keyboardType(.decimalPad)
                    TextField("Pago mínimo", text: $minimum).keyboardType(.decimalPad)
                    TextField("Pagado de este estado", text: $paid).keyboardType(.decimalPad)
                    TextField("Notas", text: $notes)
                }
                Section {
                    Text("Este importe se utiliza en el planeador mensual. Capturarlo no mueve el dinero ni reduce la deuda de la tarjeta: registra el pago real como movimiento aparte.")
                        .font(.caption).foregroundStyle(Studio.muted)
                }
            }.navigationTitle("Registrar corte").navigationBarTitleDisplayMode(.inline)
                .onAppear(perform: load)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Guardar") {
                            let item = BillingStatement(id: recordID, accountID: accountID, closingDate: closing, dueDate: due,
                                                        amountToAvoidInterest: number(toAvoid) ?? 0, statementBalance: number(totalAtCut) ?? 0, minimumPayment: number(minimum) ?? 0,
                                                        paidAmount: number(paid) ?? 0, notes: notes)
                            if store.upsertStatement(item) { dismiss() } else { error = true }
                        }.disabled(!valid)
                    }
                }.alert("No se pudo guardar", isPresented: $error) {
                    Button("Entendido", role: .cancel) { }
                } message: { Text("Revisa los importes, la fecha de corte y si ya existe ese periodo.") }
        }.preferredColorScheme(.dark)
    }
    private func load() {
        if let old = store.statements(for: accountID).first(where: { FinanceCycleMath.inMonth($0.dueDate, of: month) }) {
            recordID = old.id; closing = old.closingDate; due = old.dueDate
            toAvoid = String(old.amountToAvoidInterest); totalAtCut = String(old.statementBalance); minimum = String(old.minimumPayment)
            paid = String(old.paidAmount); notes = old.notes
        } else if let acc = account {
            totalAtCut = "0"; toAvoid = "0"; minimum = "0"
            due = FinanceCycleMath.monthDate(month, day: acc.paymentDay)
            let previous = Calendar.current.date(byAdding: .month, value: -1, to: month) ?? month
            closing = FinanceCycleMath.monthDate(acc.paymentDay <= acc.closingDay ? previous : month, day: acc.closingDay)
        }
    }
}

// MARK: - Debit with native cash semantics
struct StudioDebit: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var month = Date()
    @State private var adding = false
    @State private var sending = false
    @State private var accountID: UUID?
    @State private var preset: MovementType?
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 17) {
                StudioHeading(eyebrow: "Dinero propio", title: "Mis cuentas de débito", subtitle: "Depósitos, transferencias, compras y retiros")
                StudioSurface(glow: true) {
                    VStack(alignment: .leading, spacing: 9) {
                        Label("SALDO REAL REGISTRADO", systemImage: "banknote.fill").font(.caption2.bold()).foregroundStyle(Studio.green)
                        Text(Studio.money(store.debitBalance)).font(.system(size: 33, weight: .bold, design: .rounded))
                            .foregroundStyle(Studio.green).monospacedDigit().lineLimit(1).minimumScaleFactor(0.6)
                        Text("No incluye líneas de crédito ni préstamos.").font(.caption).foregroundStyle(Studio.muted)
                    }
                }
                StudioMonthSelector(month: $month)
                HStack(spacing: 10) {
                    StudioMetric(icon: "arrow.down.left", title: "Entradas registradas", amount: store.debitInflows(in: month), accent: Studio.green)
                    StudioMetric(icon: "arrow.up.right", title: "Salidas registradas", amount: store.debitOutflows(in: month), accent: Studio.amber)
                }
                HStack {
                    Text("Cuentas").font(.title3.bold())
                    Spacer()
                    Button { adding = true } label: { Label("Agregar cuenta", systemImage: "plus").font(.subheadline.bold()) }.foregroundStyle(Studio.green)
                }
                ForEach(store.debitAccounts) { a in
                    NavigationLink(destination: AccountDetailView(accountID: a.id)) { StudioAccountRow(account: a) }.buttonStyle(.plain)
                }
                if store.debitAccounts.isEmpty { StudioSurface { Text("Crea una cuenta para registrar tu dinero.").foregroundStyle(Studio.muted) } }
                if !store.debitAccounts.isEmpty {
                    StudioSurface {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Acciones rápidas").font(.headline)
                            HStack(spacing: 8) {
                                quick("Recibir", "arrow.down.left", .transferIn)
                                quick("Gastar", "cart", .expense)
                                quick("Depositar", "plus", .income)
                            }
                            if store.debitAccounts.count > 1 {
                                Button { sending = true } label: {
                                    Label("Transferir entre mis cuentas", systemImage: "arrow.left.arrow.right")
                                        .font(.subheadline.bold()).frame(maxWidth: .infinity).padding(13)
                                        .background(Studio.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 13))
                                }.foregroundStyle(Studio.green)
                            }
                        }
                    }
                }
                Text("Registrar una transferencia externa recibida aumenta el saldo; una enviada lo reduce. Las transferencias entre cuentas propias no son ingresos.")
                    .font(.caption).foregroundStyle(Studio.muted)
            }.padding(18).padding(.bottom, 100)
        }.background(Color.cmBackground.ignoresSafeArea()).navigationTitle("Débito").navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $adding) { AddAccountView() }
            .sheet(isPresented: $sending) { DebitTransferView() }
            .sheet(item: $preset) { selected in AddMovementView(initialAccountID: accountID, presetType: selected) }
    }
    private func quick(_ title: String, _ icon: String, _ type: MovementType) -> some View {
        Button { accountID = store.debitAccounts.first?.id; preset = type } label: {
            VStack(spacing: 7) { Image(systemName: icon).font(.headline); Text(title).font(.caption.bold()) }
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .foregroundStyle(Studio.green).background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 14))
        }
    }
}

// MARK: - Linked debt payment with atomic movement pair
struct StudioDebtPayment: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss
    let targetID: UUID
    @State private var sourceID: UUID?
    @State private var amount = ""
    @State private var date = Date()
    @State private var statementID: UUID?
    @State private var confirm = false
    @State private var error = false
    private var target: FinanceAccount? { store.accounts.first { $0.id == targetID } }
    private var amountNumber: Double { Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0 }
    private var valid: Bool {
        guard let sid = sourceID, let source = store.debitAccounts.first(where: { $0.id == sid }), let target else { return false }
        let basic = amountNumber.isFinite && amountNumber > 0 && source.available + 0.005 >= amountNumber && target.used + 0.005 >= amountNumber
        if let statementID, let statement = store.statements.first(where: { $0.id == statementID }) {
            return basic && statement.accountID == targetID && statement.pending + 0.005 >= amountNumber
        }
        return basic
    }
    var body: some View {
        NavigationStack {
            Form {
                Section("Pago entre mis cuentas") {
                    Text(target?.name ?? "Deuda").font(.headline)
                    Picker("Pagar desde débito", selection: $sourceID) {
                        Text("Seleccionar").tag(UUID?.none)
                        ForEach(store.debitAccounts) { a in Text("\(a.name) · \(Studio.money(a.available))").tag(Optional(a.id)) }
                    }
                    TextField("Monto", text: $amount).keyboardType(.decimalPad)
                    DatePicker("Fecha del pago", selection: $date, displayedComponents: .date)
                    if target?.kind == .credit {
                        Picker("Aplicar a estado de cuenta", selection: $statementID) {
                            Text("Sin asignar a corte").tag(UUID?.none)
                            ForEach(store.statements(for: targetID).filter { $0.pending > 0.005 }) { bill in
                                Text("\(bill.dueDate.formatted(.dateTime.month(.wide).year())) · \(Studio.money(bill.pending))").tag(Optional(bill.id))
                            }
                        }
                    }
                }
                Section { Text("Se descontará de tu débito y se reducirá la deuda en una sola operación. Si eliges un estado de cuenta también se actualizará su importe pendiente. No es un gasto nuevo ni un ingreso.").font(.caption).foregroundStyle(Studio.muted) }
            }.navigationTitle("Registrar pago").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button("Continuar") { confirm = true }.disabled(!valid) }
                }.confirmationDialog("Confirmar pago registrado", isPresented: $confirm, titleVisibility: .visible) {
                    Button("Registrar \(Studio.money(amountNumber))") {
                        if let sid = sourceID, store.payDebt(from: sid, to: targetID, amount: amountNumber, date: date, statementID: statementID) { dismiss() }
                        else { error = true }
                    }
                    Button("Cancelar", role: .cancel) { }
                } message: { Text("Es un registro manual, NO ejecuta una transferencia bancaria real.") }
                .alert("No se pudo registrar", isPresented: $error) { Button("Aceptar") { } }
        }.preferredColorScheme(.dark)
    }
}

// MARK: - Product-specific detail: debit never shows a credit cutoff or MSI.
struct ProAccountDetail: View {
    @EnvironmentObject private var store: FinanceStore
    let accountID: UUID
    @State private var editAccount = false
    @State private var editMovement: FinanceMovement?
    @State private var preset: MovementType?
    @State private var transfer = false
    @State private var payDebt = false
    @State private var showStatement = false
    @State private var statementMonth = Date()
    @State private var lockedTransfer = false
    @State private var deleteMovementID: UUID?
    private var account: FinanceAccount? { store.accounts.first(where: { $0.id == accountID }) }
    var body: some View {
        ScrollView(showsIndicators: false) {
            if let a = account {
                VStack(alignment: .leading, spacing: 17) {
                    if a.kind == .loan {
                        StudioSurface(glow: true) {
                            HStack(spacing: 15) {
                                Image(systemName: "building.columns.fill")
                                    .font(.title).foregroundStyle(Studio.green)
                                    .frame(width: 57, height: 57)
                                    .background(Studio.green.opacity(0.13), in: RoundedRectangle(cornerRadius: 18))
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("MI PRÉSTAMO").font(.caption2.bold()).tracking(1.5).foregroundStyle(Studio.muted)
                                    Text(a.name).font(.title3.bold())
                                    Text("Saldo y calendario de cuotas").font(.caption).foregroundStyle(Studio.muted)
                                }
                                Spacer()
                            }.padding(.vertical, 7)
                        }
                    } else { CMCardFace(account: a, compact: false) }
                    StudioSurface {
                        VStack(alignment: .leading, spacing: 13) {
                            Text(a.kind == .debit ? "SALDO DISPONIBLE" : "DEUDA REGISTRADA")
                                .font(.caption2.bold()).foregroundStyle(Studio.muted)
                            Text(Studio.money(a.kind == .debit ? a.available : a.used))
                                .font(.system(size: 30, weight: .bold, design: .rounded)).foregroundStyle(a.kind == .debit ? Studio.green : .white)
                            if a.kind == .credit {
                                line("Crédito autorizado", Studio.money(a.limit))
                                line("Crédito disponible", Studio.money(a.available))
                                line("Corte habitual", "Día \(a.closingDay)")
                                line("Pago habitual", "Día \(a.paymentDay)")
                                StudioProgress(value: a.utilization, color: creditTone(a.utilization))
                                Text("Uso \(a.utilization.formatted(.percent.precision(.fractionLength(1)))) · Referencia 30 % orientativa")
                                    .font(.caption).foregroundStyle(creditTone(a.utilization))
                            } else if a.kind == .loan {
                                line("Monto original registrado", Studio.money(a.limit))
                                line("Día habitual de cuota", "\(a.paymentDay)")
                                Text("El saldo de liquidación oficial puede incluir intereses y comisiones.").font(.caption).foregroundStyle(Studio.muted)
                            } else {
                                line("Banco", a.bankID.isEmpty ? a.name : BankCatalog.name(for: a.bankID))
                                line("Red", a.network)
                                Text("En débito no existen corte, pago mínimo ni línea de crédito.").font(.caption).foregroundStyle(Studio.muted)
                            }
                        }
                    }
                    if a.kind == .debit {
                        Text("Nuevo movimiento").font(.title3.bold())
                        HStack(spacing: 8) {
                            action("Ingreso", "plus", .income)
                            action("Gasto", "cart", .expense)
                            action("Recibir", "arrow.down.left", .transferIn)
                        }
                        HStack(spacing: 8) {
                            action("Enviar", "arrow.up.right", .transferOut)
                            action("Devolución", "arrow.uturn.backward", .refund)
                            if store.debitAccounts.count > 1 {
                                Button { transfer = true } label: {
                                    Label("Entre cuentas", systemImage: "arrow.left.arrow.right").font(.caption.bold()).frame(maxWidth: .infinity).padding(12)
                                }.foregroundStyle(Studio.green).background(Color.cmPanel, in: RoundedRectangle(cornerRadius: 13))
                            }
                        }
                    } else {
                        if a.kind == .credit {
                            HStack { Text("Estado de cuenta").font(.title3.bold()); Spacer(); Button("Capturar corte") { statementMonth = Date(); showStatement = true }.font(.caption.bold()).foregroundStyle(Studio.green) }
                            let bills = store.statements(for: a.id)
                            if bills.isEmpty { StudioSurface { Text("Captura el pago para no generar intereses del estado de cuenta. El saldo total de la tarjeta no es automáticamente lo que vence este mes.").font(.caption).foregroundStyle(Studio.muted) } }
                            else {
                                ForEach(bills.prefix(2)) { bill in
                                    Button { statementMonth = bill.dueDate; showStatement = true } label: {
                                        StudioSurface {
                                            VStack(alignment: .leading, spacing: 7) {
                                                HStack { Text("Pago \(bill.dueDate.formatted(.dateTime.month(.wide)))").font(.headline); Spacer(); Image(systemName: "pencil").foregroundStyle(Studio.green) }
                                                Text(Studio.money(bill.pending)).font(.title3.bold()).foregroundStyle(Studio.green)
                                                Text("PNGI restante registrado · vence \(bill.dueDate.formatted(date: .abbreviated, time: .omitted))")
                                                    .font(.caption).foregroundStyle(Studio.muted)
                                                Text("Saldo al corte: \(Studio.money(bill.statementBalance)) · Mínimo: \(Studio.money(bill.minimumPayment))")
                                                    .font(.caption2).foregroundStyle(Studio.muted)
                                            }
                                        }
                                    }.buttonStyle(.plain)
                                }
                            }
                        }
                        if !store.debitAccounts.isEmpty {
                            Button { payDebt = true } label: {
                                Label("Registrar pago desde débito", systemImage: "arrow.left.arrow.right.circle.fill")
                                    .frame(maxWidth: .infinity).padding(15).background(Studio.green, in: RoundedRectangle(cornerRadius: 16))
                            }.buttonStyle(.plain).foregroundStyle(.black).font(.headline)
                        }
                        AccountPlansSection(account: a)
                    }
                    HStack { Text("Movimientos").font(.title3.bold()); Spacer(); Button { preset = a.kind == .debit ? .expense : (a.kind == .credit ? .purchase : .loanPayment) } label: { Label("Agregar", systemImage: "plus").font(.subheadline.bold()) }.foregroundStyle(Studio.green) }
                    let recent = store.movements.filter { $0.accountID == a.id }
                    if recent.isEmpty { StudioSurface { Text("Todavía no hay movimientos registrados.").foregroundStyle(Studio.muted) } }
                    ForEach(recent) { m in
                        Button {
                            if m.transferGroupID == nil { editMovement = m } else { lockedTransfer = true }
                        } label: { StudioMovementRow(movement: m) }.buttonStyle(.plain)
                        .contextMenu {
                            if m.transferGroupID == nil { Button("Editar") { editMovement = m } }
                            Button("Eliminar movimiento", role: .destructive) { deleteMovementID = m.id }
                        }
                    }
                }.padding(18).padding(.bottom, 110)
            } else { ContentUnavailableView("Cuenta no encontrada", systemImage: "exclamationmark.circle") }
        }.background(Color.cmBackground.ignoresSafeArea()).navigationTitle(account?.name ?? "Detalle").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Editar") { editAccount = true }.foregroundStyle(Studio.green) } }
            .sheet(isPresented: $editAccount) { if let a = account { EditAccountView(account: a) } }
            .sheet(item: $preset) { AddMovementView(initialAccountID: accountID, presetType: $0) }
            .sheet(item: $editMovement) { AddMovementView(existing: $0) }
            .sheet(isPresented: $transfer) { DebitTransferView() }
            .sheet(isPresented: $payDebt) { StudioDebtPayment(targetID: accountID) }
            .sheet(isPresented: $showStatement) { StudioStatementEditor(accountID: accountID, month: statementMonth) }
            .alert("Transferencia vinculada", isPresented: $lockedTransfer) { Button("Aceptar") { } } message: {
                Text("Para corregir una transferencia entre cuentas, elimina el par vinculado y registra de nuevo la operación.")
            }
            .confirmationDialog("¿Eliminar movimiento?", isPresented: Binding(get: { deleteMovementID != nil }, set: { if !$0 { deleteMovementID = nil } }), titleVisibility: .visible) {
                Button("Eliminar y revertir saldo", role: .destructive) { if let id = deleteMovementID { store.deleteMovement(id) }; deleteMovementID = nil }
                Button("Cancelar", role: .cancel) { deleteMovementID = nil }
            } message: { Text("Se revertirá su efecto contable. Si es una transferencia propia se eliminarán ambos lados.") }
    }
    private func action(_ title: String, _ icon: String, _ type: MovementType) -> some View {
        Button { preset = type } label: {
            Label(title, systemImage: icon).font(.caption.bold()).frame(maxWidth: .infinity).padding(.vertical, 13)
        }.foregroundStyle(Studio.green).background(Color.cmPanel, in: RoundedRectangle(cornerRadius: 13))
    }
    private func line(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label).foregroundStyle(Studio.muted)
            Spacer(minLength: 4)
            Text(value).fontWeight(.medium).multilineTextAlignment(.trailing)
        }.font(.subheadline)
    }
}

// MARK: - Transactions and analysis
struct StudioMovementRow: View {
    @EnvironmentObject private var store: FinanceStore
    let movement: FinanceMovement
    private var account: FinanceAccount? { store.accounts.first(where: { $0.id == movement.accountID }) }
    private var effect: Double { store.movementEffect(movement, kind: account?.kind ?? .credit) }
    private var beneficial: Bool { effect < 0 }
    private var label: String {
        if account?.kind == .debit { return beneficial ? "+" : "−" }
        return beneficial ? "↓ " : "↑ "
    }
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: beneficial ? "arrow.down.left" : "arrow.up.right")
                .foregroundStyle(beneficial ? Studio.green : Studio.amber)
                .frame(width: 39, height: 39).background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 13))
            VStack(alignment: .leading, spacing: 4) {
                Text(movement.title).font(.subheadline.bold()).lineLimit(1)
                Text("\(account?.name ?? "Cuenta") · \(movement.date.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption2).foregroundStyle(Studio.muted).lineLimit(1)
                if movement.category != "Otros" { Text(movement.category).font(.system(size: 10)).foregroundStyle(Studio.muted) }
            }
            Spacer(minLength: 4)
            Text(label + Studio.money(movement.amount)).font(.subheadline.bold()).monospacedDigit()
                .foregroundStyle(beneficial ? Studio.green : .white).lineLimit(1).minimumScaleFactor(0.57)
        }.padding(12).background(Color.cmPanel, in: RoundedRectangle(cornerRadius: 17))
    }
}

struct StudioAccounts: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var selected: AccountKind = .credit
    @State private var search = ""
    @State private var adding = false
    private var filtered: [FinanceAccount] { store.accounts.filter { $0.kind == selected && (search.isEmpty || $0.name.localizedCaseInsensitiveContains(search)) } }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        StudioHeading(eyebrow: "Todos tus productos", title: "Mis cuentas", subtitle: "Cada producto con sus propias reglas")
                        Button { adding = true } label: { Image(systemName: "plus").foregroundStyle(Studio.green).font(.title2).frame(width: 43, height: 43).background(Color.cmPanel, in: Circle()) }.padding(.top, 14)
                    }
                    Picker("Producto", selection: $selected) {
                        ForEach(AccountKind.allCases) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.segmented)
                    HStack(spacing: 9) {
                        Image(systemName: "magnifyingglass")
                        TextField("Buscar cuenta", text: $search)
                    }.font(.subheadline).padding(14).background(Color.cmPanel, in: RoundedRectangle(cornerRadius: 14))
                    if selected == .credit {
                        HStack(spacing: 10) {
                            StudioMetric(icon: "creditcard", title: "Límite total", amount: store.totalLimit)
                            StudioMetric(icon: "arrow.up.right", title: "Utilizado", amount: store.totalUsedCredit, accent: creditTone(store.creditUtilization))
                        }
                    } else if selected == .debit { StudioMetric(icon: "banknote", title: "Dinero propio", amount: store.debitBalance, accent: Studio.green) }
                    else { StudioMetric(icon: "building.columns", title: "Deuda de préstamos", amount: store.totalLoanDebt) }
                    ForEach(filtered) { a in
                        NavigationLink(destination: AccountDetailView(accountID: a.id)) { StudioAccountRow(account: a) }.buttonStyle(.plain)
                    }
                    if filtered.isEmpty { StudioSurface { Text("No hay cuentas de este tipo. Pulsa + para registrar una.").foregroundStyle(Studio.muted) } }
                    if selected == .debit { NavigationLink(destination: StudioDebit()) { Label("Abrir centro de débito", systemImage: "arrow.right.circle.fill").foregroundStyle(Studio.green).font(.subheadline.bold()) } }
                }.padding(18).padding(.bottom, 125)
            }.background(Color.cmBackground.ignoresSafeArea()).toolbar(.hidden, for: .navigationBar)
                .sheet(isPresented: $adding) { AddAccountView() }
        }
    }
}

struct StudioTransactions: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var search = ""
    @State private var filter = "Todos"
    @State private var month = Date()
    @State private var adding = false
    @State private var editing: FinanceMovement?
    @State private var lockedTransfer = false
    @State private var deleting: UUID?
    private var filters: [String] { ["Todos", "Gastos", "Entradas", "Pagos", "Transferencias"] }
    private var filtered: [FinanceMovement] {
        store.movements.filter { m in
            guard FinanceCycleMath.inMonth(m.date, of: month) else { return false }
            if !search.isEmpty && !m.title.localizedCaseInsensitiveContains(search) { return false }
            switch filter {
            case "Gastos": return m.type == .purchase || m.type == .expense || (m.type == nil && !m.isPayment)
            case "Entradas": return m.type == .income || m.type == .refund
            case "Pagos": return m.type == .cardPayment || m.type == .loanPayment
            case "Transferencias": return m.type == .transferIn || m.type == .transferOut
            default: return true
            }
        }
    }
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        StudioHeading(eyebrow: "Registro personal", title: "Movimientos", subtitle: "Edita compras, depósitos y pagos")
                        Button { adding = true } label: { Image(systemName: "plus").foregroundStyle(Studio.green).font(.title2).frame(width: 43, height: 43).background(Color.cmPanel, in: Circle()) }.disabled(store.accounts.isEmpty).padding(.top, 14)
                    }
                    StudioMonthSelector(month: $month)
                    HStack(spacing: 10) {
                        StudioMetric(icon: "arrow.down.left", title: "Entradas débito", amount: store.debitInflows(in: month), accent: Studio.green)
                        StudioMetric(icon: "arrow.up.right", title: "Gastos débito", amount: store.debitOutflows(in: month), accent: Studio.amber)
                    }
                    HStack { Image(systemName: "magnifyingglass"); TextField("Buscar por concepto", text: $search) }
                        .font(.subheadline).padding(13).background(Color.cmPanel, in: RoundedRectangle(cornerRadius: 14))
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 7) {
                            ForEach(filters, id: \.self) { name in
                                Button { filter = name } label: {
                                    Text(name).font(.caption.bold()).padding(.horizontal, 13).padding(.vertical, 10)
                                        .background(filter == name ? Studio.green : Color.cmPanel, in: Capsule())
                                        .foregroundStyle(filter == name ? .black : .white)
                                }
                            }
                        }
                    }
                    ForEach(filtered) { m in
                        Button { if m.transferGroupID != nil { lockedTransfer = true } else { editing = m } } label: {
                            StudioMovementRow(movement: m)
                        }.buttonStyle(.plain).contextMenu {
                            if m.transferGroupID == nil { Button("Editar") { editing = m } }
                            Button("Eliminar y revertir", role: .destructive) { deleting = m.id }
                        }
                    }
                    if filtered.isEmpty { StudioSurface { Text("Sin movimientos en este mes o filtro.").foregroundStyle(Studio.muted) } }
                    Text("Los pagos de tarjeta y las transferencias internas no son gastos nuevos. Las compras de crédito cuentan como gasto por fecha de operación, aunque se paguen después.")
                        .font(.caption2).foregroundStyle(Studio.muted)
                }.padding(18).padding(.bottom, 125)
            }.background(Color.cmBackground.ignoresSafeArea()).toolbar(.hidden, for: .navigationBar)
                .sheet(isPresented: $adding) { AddMovementView() }
                .sheet(item: $editing) { AddMovementView(existing: $0) }
                .alert("Movimiento vinculado", isPresented: $lockedTransfer) { Button("Entendido") { } } message: { Text("Para corregir transferencias propias o pagos desde débito, elimina la pareja y vuelve a registrarla.") }
                .confirmationDialog("¿Eliminar movimiento?", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }), titleVisibility: .visible) {
                    Button("Eliminar y revertir saldo", role: .destructive) { if let id = deleting { store.deleteMovement(id) }; deleting = nil }
                    Button("Cancelar", role: .cancel) { deleting = nil }
                } message: { Text("Esta acción revierte el movimiento y, si está vinculado, ambos registros.") }
        }
    }
}

private struct StudioCategoryRow: View {
    let name: String
    let amount: Double
    let maxAmount: Double
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(name).font(.subheadline)
                Spacer()
                Text(Studio.money(amount)).font(.subheadline.bold()).monospacedDigit()
            }
            StudioProgress(value: maxAmount > 0 ? amount/maxAmount : 0, color: Studio.blue)
        }
    }
}

struct StudioAnalytics: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var month = Date()
    private var monthSeries: [Date] {
        (0..<6).reversed().compactMap { Calendar.current.date(byAdding: .month, value: -$0, to: FinanceCycleMath.monthStart(month)) }
    }
    private var categories: [(name: String, total: Double)] { store.spendByCategory(in: month) }
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 17) {
                    StudioHeading(eyebrow: "Tu información", title: "Análisis", subtitle: "Gráficas reales a partir de movimientos registrados")
                    StudioMonthSelector(month: $month)
                    StudioSurface {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack { Text("Crédito utilizado").font(.headline); Spacer(); Text(store.creditUtilization.formatted(.percent.precision(.fractionLength(1)))).font(.headline.bold()).foregroundStyle(creditTone(store.creditUtilization)) }
                            StudioProgress(value: store.creditUtilization, color: creditTone(store.creditUtilization))
                            HStack {
                                stat("Límite", store.totalLimit)
                                Spacer()
                                stat("Utilizado", store.totalUsedCredit)
                                Spacer()
                                stat("Disponible", store.availableCredit)
                            }
                        }
                    }
                    StudioSurface {
                        VStack(alignment: .leading, spacing: 13) {
                            Text("Deuda por producto").font(.headline)
                            Text("Nombres completos, sin etiquetas encimadas").font(.caption2).foregroundStyle(Studio.muted)
                            let debts = store.accounts.filter { $0.kind != .debit }.sorted { $0.used > $1.used }
                            let maxDebt = debts.map(\.used).max() ?? 0
                            if debts.isEmpty { Text("Agrega tarjetas o préstamos.").foregroundStyle(Studio.muted) }
                            ForEach(debts) { account in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack { Text(account.name).font(.subheadline).lineLimit(2); Spacer(); Text(Studio.money(account.used)).font(.subheadline.bold()).monospacedDigit().minimumScaleFactor(0.7) }
                                    StudioProgress(value: maxDebt > 0 ? account.used/maxDebt : 0,
                                                   color: account.kind == .credit ? creditTone(account.utilization) : Studio.blue)
                                }
                            }
                        }
                    }
                    StudioSurface {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack { Text("Entradas y gastos · débito").font(.headline); Spacer(); Image(systemName: "chart.bar.xaxis").foregroundStyle(Studio.green) }
                            Chart {
                                ForEach(monthSeries, id: \.self) { date in
                                    BarMark(x: .value("Mes", date, unit: .month), y: .value("Entradas", store.debitInflows(in: date)))
                                        .foregroundStyle(Studio.green).position(by: .value("Movimiento", "Entradas"))
                                    BarMark(x: .value("Mes", date, unit: .month), y: .value("Gastos", store.debitOutflows(in: date)))
                                        .foregroundStyle(Studio.amber).position(by: .value("Movimiento", "Gastos"))
                                }
                            }.chartLegend(position: .bottom).frame(height: 210)
                            Text("Entradas y salidas de efectivo registradas, incluidos pagos de deuda. Las transferencias entre cuentas propias se excluyen.")
                                .font(.caption2).foregroundStyle(Studio.muted)
                        }
                    }
                    StudioSurface {
                        VStack(alignment: .leading, spacing: 13) {
                            Text("Gastos por categoría").font(.headline)
                            if categories.isEmpty { Text("Registra compras con una categoría para verlas aquí.").foregroundStyle(Studio.muted).font(.caption) }
                            let maxCat = categories.first?.total ?? 0
                            ForEach(0..<min(categories.count, 8), id: \.self) { index in
                                StudioCategoryRow(name: categories[index].name, amount: categories[index].total, maxAmount: maxCat)
                            }
                            Text("Incluye compras de crédito y gastos de débito; excluye pagos de tarjetas para evitar duplicaciones.")
                                .font(.caption2).foregroundStyle(Studio.muted)
                        }
                    }
                    StudioSurface {
                        VStack(alignment: .leading, spacing: 9) {
                            Text("Balance registrado").font(.headline)
                            HStack { Text("Mi dinero"); Spacer(); Text(Studio.money(store.debitBalance)).foregroundStyle(Studio.green) }
                            HStack { Text("Deuda en crédito"); Spacer(); Text(Studio.money(store.totalUsedCredit)) }
                            HStack { Text("Deuda de préstamos"); Spacer(); Text(Studio.money(store.totalLoanDebt)) }
                            Divider().overlay(.white.opacity(0.15))
                            HStack { Text("Balance neto parcial").fontWeight(.semibold); Spacer(); Text(Studio.money(store.netBalance)).fontWeight(.bold) }
                            Text("Parcial: no incluye efectivo no registrado, inversiones u otros bienes y deudas.").font(.caption2).foregroundStyle(Studio.muted)
                        }.font(.subheadline)
                    }
                }.padding(18).padding(.bottom, 125)
            }.background(Color.cmBackground.ignoresSafeArea()).toolbar(.hidden, for: .navigationBar)
        }
    }
    private func stat(_ title: String, _ value: Double) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.caption2).foregroundStyle(Studio.muted)
            Text(Studio.money(value)).font(.caption.bold()).monospacedDigit().lineLimit(1).minimumScaleFactor(0.65)
        }
    }
}

// MARK: - Wallet: cards remain individually tappable, no overlapping stack hit areas
struct StudioWallet: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var selectedID: UUID?
    @State private var showNew = false
    private var cards: [FinanceAccount] { store.accounts.filter { $0.kind != .loan } }
    private var current: FinanceAccount? { cards.first(where: { $0.id == selectedID }) ?? cards.first }
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 17) {
                HStack {
                    StudioHeading(eyebrow: "Colección personal", title: "Wallet", subtitle: "Cada tarjeta, sin perder el contexto")
                    Button { showNew = true } label: {
                        Image(systemName: "plus").font(.title2).foregroundStyle(Studio.green)
                            .frame(width: 43, height: 43).background(Color.cmPanel, in: Circle())
                    }.padding(.top, 10)
                }
                if let card = current {
                    NavigationLink(destination: AccountDetailView(accountID: card.id)) {
                        CMCardFace(account: card)
                    }.buttonStyle(.plain)
                    StudioSurface {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack { Text(card.name).font(.headline); Spacer(); Text(card.kind.rawValue).font(.caption).foregroundStyle(Studio.muted) }
                            HStack(spacing: 10) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(card.kind == .debit ? "Dinero disponible" : "Crédito libre").font(.caption).foregroundStyle(Studio.muted)
                                    Text(Studio.money(card.available)).font(.subheadline.bold()).foregroundStyle(Studio.green)
                                }
                                Spacer()
                                if card.kind == .credit {
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("Deuda actual").font(.caption).foregroundStyle(Studio.muted)
                                        Text(Studio.money(card.used)).font(.subheadline.bold())
                                    }
                                }
                            }
                            if card.kind == .credit { StudioProgress(value: card.utilization, color: creditTone(card.utilization)) }
                            NavigationLink(destination: AccountDetailView(accountID: card.id)) {
                                HStack { Text("Abrir movimientos y detalles"); Spacer(); Image(systemName: "arrow.up.right") }
                                    .font(.subheadline.bold()).foregroundStyle(Studio.green)
                            }
                        }
                    }
                } else {
                    StudioSurface { Text("Todavía no tienes tarjetas registradas.").foregroundStyle(Studio.muted) }
                }
                HStack { Text("Seleccionar tarjeta").font(.title3.bold()); Spacer(); Text("\(cards.count) registradas").font(.caption).foregroundStyle(Studio.muted) }
                ForEach(cards) { card in
                    Button { withAnimation(.easeInOut(duration: 0.2)) { selectedID = card.id } } label: {
                        HStack(spacing: 12) {
                            CMBrandBadge(account: card, size: 41)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(card.name).font(.subheadline.bold()).foregroundStyle(.white)
                                Text(card.kind.rawValue).font(.caption2).foregroundStyle(Studio.muted)
                            }
                            Spacer()
                            Text(Studio.money(card.available)).font(.caption.bold()).foregroundStyle(Studio.green).lineLimit(1).minimumScaleFactor(0.6)
                            Image(systemName: current?.id == card.id ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(current?.id == card.id ? Studio.green : Studio.muted)
                        }.padding(13).background(current?.id == card.id ? Studio.green.opacity(0.11) : Color.cmPanel,
                                                 in: RoundedRectangle(cornerRadius: 16))
                    }.buttonStyle(.plain)
                }
                Text("Las tarjetas son representaciones visuales de tus cuentas registradas; no contienen datos bancarios ni de Apple Wallet.")
                    .font(.caption2).foregroundStyle(Studio.muted)
            }.padding(18).padding(.bottom, 115)
        }.background(Color.cmBackground.ignoresSafeArea()).navigationTitle("Wallet").navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showNew) { AddAccountView() }
    }
}
