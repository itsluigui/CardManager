import SwiftUI
import Charts
import UniformTypeIdentifiers

extension Color {
    static let cmGreen = Color(red: 0.20, green: 0.96, blue: 0.39)
    static let cmBackground = Color(red: 0.025, green: 0.035, blue: 0.032)
    static let cmPanel = Color(red: 0.075, green: 0.090, blue: 0.085)
}

private func nextAccountDue(day: Int) -> Date? {
    let cal = Calendar.current
    let today = cal.startOfDay(for: .now)
    for offset in 0...1 {
        guard let month = cal.date(byAdding: .month, value: offset, to: today),
              let range = cal.range(of: .day, in: .month, for: month) else { continue }
        let d = min(max(day, 1), range.count)
        var parts = cal.dateComponents([.year, .month], from: month)
        parts.day = d
        if let date = cal.date(from: parts), date >= today { return date }
    }
    return nil
}

private func peso(_ amount: Double) -> String { amount.formatted(.currency(code: "MXN")) }
private func pct(_ amount: Double) -> String { amount.formatted(.percent.precision(.fractionLength(1))) }
private func bankName(_ account: FinanceAccount) -> String {
    account.bankID.isEmpty ? account.name : BankCatalog.name(for: account.bankID)
}
private func cardColor(_ account: FinanceAccount) -> [Color] {
    let bank = account.bankID.isEmpty ? account.name.lowercased() : account.bankID
    switch bank {
    case let x where x.contains("rappi"): return [Color(red: 0.92, green: 0.10, blue: 0.18), Color(red: 0.38, green: 0.015, blue: 0.07)]
    case let x where x.contains("nu"): return [Color(red: 0.56, green: 0.24, blue: 0.88), Color(red: 0.20, green: 0.06, blue: 0.42)]
    case let x where x.contains("mercado"): return [Color(red: 0.05, green: 0.53, blue: 0.95), Color(red: 0.03, green: 0.15, blue: 0.55)]
    case let x where x.contains("bbva"): return [Color(red: 0.07, green: 0.46, blue: 0.82), Color(red: 0.025, green: 0.13, blue: 0.40)]
    case let x where x.contains("plata"): return [Color(red: 0.77, green: 0.79, blue: 0.84), Color(red: 0.32, green: 0.34, blue: 0.42)]
    case let x where x.contains("amex"): return [Color(red: 0.09, green: 0.45, blue: 0.92), Color(red: 0.02, green: 0.19, blue: 0.55)]
    case let x where x.contains("revolut"): return [Color(red: 0.45, green: 0.48, blue: 0.54), Color(red: 0.13, green: 0.14, blue: 0.20)]
    default: return [Color(red: 0.16, green: 0.36, blue: 0.25), Color(red: 0.035, green: 0.13, blue: 0.09)]
    }
}
private func bankSymbol(_ account: FinanceAccount) -> String {
    let bank = account.bankID.isEmpty ? account.name.lowercased() : account.bankID
    if bank.contains("revolut") { return "R" }
    if bank.contains("rappi") { return "●●" }
    if bank.contains("mercado") { return "MP" }
    if bank.contains("nu") { return "nu" }
    if bank.contains("bbva") { return "BB" }
    if bank.contains("plata") { return "P" }
    return String(account.name.prefix(2)).uppercased()
}

struct CMPanel<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content.padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cmPanel, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.07), lineWidth: 1))
    }
}
struct CMTitle: View {
    let text: String
    var body: some View { Text(text).font(.system(size: 23, weight: .bold, design: .rounded)).foregroundStyle(.white) }
}
struct CMBrandBadge: View {
    let account: FinanceAccount
    var size: CGFloat = 42
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.26)
                .fill(LinearGradient(colors: cardColor(account), startPoint: .topLeading, endPoint: .bottomTrailing))
            Text(bankSymbol(account)).font(.system(size: size * 0.32, weight: .black, design: .rounded))
                .foregroundStyle(.white).minimumScaleFactor(0.5)
        }.frame(width: size, height: size)
            .overlay(RoundedRectangle(cornerRadius: size * 0.26).stroke(.white.opacity(0.14)))
    }
}
struct CMMarketGlow: View {
    let values: [CGFloat] = [0.72, 0.52, 0.61, 0.31, 0.42, 0.17, 0.27, 0.11, 0.21, 0.06]
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(colors: [.cmGreen.opacity(0.11), .clear], startPoint: .topTrailing, endPoint: .bottomLeading)
                Path { path in
                    for (i, v) in values.enumerated() {
                        let p = CGPoint(x: proxy.size.width * CGFloat(i) / CGFloat(values.count - 1), y: proxy.size.height * v)
                        if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
                    }
                }.stroke(Color.cmGreen.opacity(0.50), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }
        }.accessibilityLabel("Gráfica de fondo decorativa; no representa cotizaciones")
    }
}
struct CMCardFace: View {
    let account: FinanceAccount
    var compact: Bool = false
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 20).fill(LinearGradient(colors: cardColor(account), startPoint: .topLeading, endPoint: .bottomTrailing))
            GeometryReader { g in
                Circle().stroke(.white.opacity(0.12), lineWidth: 34)
                    .frame(width: g.size.width * 0.75, height: g.size.width * 0.75)
                    .offset(x: g.size.width * 0.53, y: -g.size.height * 0.7)
                Circle().fill(.white.opacity(0.09)).frame(width: 120, height: 120)
                    .blur(radius: 28).offset(x: -30, y: 70)
            }.clipped()
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    Text(bankName(account)).font(.system(size: compact ? 21 : 26, weight: .black, design: .rounded))
                        .lineLimit(1).minimumScaleFactor(0.7)
                    Spacer()
                    Image(systemName: "wave.3.right").rotationEffect(.degrees(90)).font(.title3)
                }
                Spacer(minLength: 12)
                if !compact {
                    RoundedRectangle(cornerRadius: 4).fill(LinearGradient(colors: [.yellow.opacity(0.85), .white.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 32, height: 24)
                    Spacer(minLength: 8)
                }
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(account.kind.rawValue.uppercased()).font(.system(size: 9, weight: .semibold)).tracking(1.4).opacity(0.75)
                        Text(compact ? "••••  " + String(account.id.uuidString.suffix(4)) : peso(account.available))
                            .font(.system(size: compact ? 13 : 22, weight: .bold, design: .rounded))
                            .lineLimit(1).minimumScaleFactor(0.65)
                    }
                    Spacer()
                    Text(account.network == "Sin especificar" ? "CARD" : account.network.uppercased())
                        .font(.system(size: compact ? 10 : 12, weight: .heavy, design: .rounded)).italic().lineLimit(1)
                }
            }.padding(compact ? 17 : 21).foregroundStyle(.white)
        }
        .frame(height: compact ? 142 : 190)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.17)))
        .shadow(color: cardColor(account)[0].opacity(0.18), radius: 12, y: 7)
    }
}

struct PremiumHome: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var showCalendar = false
    private var available: Double { max(0, store.totalLimit - store.totalUsedCredit) }
    private var ratio: Double { store.totalLimit > 0 ? store.totalUsedCredit / store.totalLimit : 0 }
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 17) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack(spacing: 4) { Text("Card Manager").foregroundStyle(.white); Text("Pro").foregroundStyle(Color.cmGreen) }
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                            Text("Tu control financiero, en un solo lugar.").font(.caption).foregroundStyle(.white.opacity(0.58))
                        }
                        Spacer()
                        Image(systemName: "chart.xyaxis.line").foregroundStyle(Color.cmGreen)
                            .frame(width: 39, height: 39).background(Color.cmPanel, in: Circle())
                    }.padding(.top, 12)
                    ZStack {
                        RoundedRectangle(cornerRadius: 22).fill(Color.cmPanel)
                        CMMarketGlow().opacity(0.75).clipShape(RoundedRectangle(cornerRadius: 22))
                        HStack(spacing: 10) {
                            metric("Deuda total", peso(store.totalDebt), "arrow.up.right", .white)
                            metric("Crédito disponible", peso(available), "arrow.down.left", .cmGreen)
                        }.padding(13)
                    }.frame(height: 108)
                    CMPanel {
                        VStack(alignment: .leading, spacing: 11) {
                            HStack {
                                Text("Uso de crédito general").font(.subheadline.bold())
                                Spacer()
                                Text(pct(ratio)).font(.headline.bold()).foregroundStyle(Color.cmGreen)
                            }
                            GeometryReader { g in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(.white.opacity(0.11))
                                    Capsule().fill(ratio > 0.5 ? Color.orange : Color.cmGreen)
                                        .frame(width: g.size.width * min(1, max(0, ratio)))
                                }
                            }.frame(height: 9)
                            HStack {
                                Text("Referencia orientativa: 30%").foregroundStyle(.white.opacity(0.50))
                                Spacer()
                                Text(peso(store.totalLimit) + " límite").foregroundStyle(.white.opacity(0.65))
                            }.font(.caption2)
                        }
                    }
                    HStack {
                        Label("Próximos pagos", systemImage: "calendar").font(.headline)
                        Spacer()
                        Button("Ver calendario") { showCalendar = true }.font(.caption.bold()).foregroundStyle(Color.cmGreen)
                    }
                    CMPanel {
                        VStack(spacing: 12) {
                            let pending = store.accounts.filter { $0.kind != .debit }.sorted { $0.paymentDay < $1.paymentDay }
                            if pending.isEmpty {
                                Text("Agrega una tarjeta para consultar sus fechas de pago.").font(.subheadline).foregroundStyle(.secondary)
                            }
                            ForEach(pending.prefix(3)) { account in
                                HStack(spacing: 10) {
                                    CMBrandBadge(account: account, size: 35)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(account.name).font(.subheadline.bold())
                                        Text("Pago · día \(account.paymentDay)").font(.caption2).foregroundStyle(.secondary)
                                        if let due = nextAccountDue(day: account.paymentDay) {
                                            PaymentCountdown(date: due)
                                        }
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 2) {
                                        if let plan = store.plans(for: account.id).filter({ !$0.isFinished }).sorted(by: { $0.nextPaymentDate < $1.nextPaymentDate }).first {
                                            Text(peso(plan.monthlyAmount)).font(.caption.bold())
                                            Text("Cuota registrada").font(.caption2).foregroundStyle(.secondary)
                                        } else {
                                            Text(peso(account.used)).font(.caption.bold())
                                            Text("Saldo total, no pago mínimo").font(.caption2).foregroundStyle(.secondary)
                                        }
                                    }.lineLimit(1).minimumScaleFactor(0.7)
                                }
                            }
                        }
                    }
                    HStack {
                        CMTitle(text: "Tus tarjetas")
                        Spacer()
                        Text("\(store.accounts.count) registradas").font(.caption).foregroundStyle(.secondary)
                    }
                    if let first = store.accounts.first {
                        NavigationLink(destination: AccountDetailView(accountID: first.id)) {
                            CMCardFace(account: first, compact: true)
                        }.buttonStyle(.plain)
                    } else {
                        CMPanel { Text("Agrega tu primera tarjeta desde la sección Tarjetas.").foregroundStyle(.secondary) }
                    }
                    HStack {
                        CMTitle(text: "Actividad reciente")
                        Spacer()
                        Text("Registro manual").font(.caption2).foregroundStyle(.secondary)
                    }
                    ForEach(store.movements.prefix(3)) { m in
                        movementRow(m, accounts: store.accounts)
                    }
                    if store.movements.isEmpty { Text("Tus movimientos aparecerán aquí.").font(.caption).foregroundStyle(.secondary) }
                    Text("Los datos son registrados manualmente. No existe conexión en vivo con bancos ni mercados.")
                        .font(.caption2).foregroundStyle(.secondary).padding(.bottom, 15)
                }.padding(.horizontal, 18)
            }
            .background(Color.cmBackground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showCalendar) { PremiumCalendar() }
        }
    }
    private func metric(_ title: String, _ value: String, _ symbol: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 5) { Image(systemName: symbol).foregroundStyle(Color.cmGreen); Text(title).foregroundStyle(.white.opacity(0.70)) }
                .font(.system(size: 10, weight: .medium))
            Text(value).font(.system(size: 19, weight: .bold, design: .rounded)).foregroundStyle(color).lineLimit(1).minimumScaleFactor(0.55)
        }.frame(maxWidth: .infinity, alignment: .leading)
            .padding(12).background(.black.opacity(0.29), in: RoundedRectangle(cornerRadius: 14))
    }
}

private func movementRow(_ m: FinanceMovement, accounts: [FinanceAccount]) -> some View {
    let account = accounts.first(where: { $0.id == m.accountID })
    return HStack(spacing: 12) {
        Image(systemName: m.isPayment ? "arrow.down.left" : "bag.fill")
            .foregroundStyle(m.isPayment ? Color.cmGreen : Color.white)
            .frame(width: 38, height: 38).background(Color.cmPanel, in: RoundedRectangle(cornerRadius: 12))
        VStack(alignment: .leading, spacing: 4) {
            Text(m.title).font(.subheadline.bold()).lineLimit(1)
            Text((account?.name ?? "Cuenta") + " · " + m.date.formatted(date: .abbreviated, time: .omitted))
                .font(.caption2).foregroundStyle(.secondary)
        }
        Spacer()
        Text((m.isPayment ? "−" : "+") + peso(m.amount))
            .font(.caption.bold()).foregroundStyle(m.isPayment ? Color.cmGreen : .white).lineLimit(1).minimumScaleFactor(0.65)
    }.padding(12).background(Color.cmPanel, in: RoundedRectangle(cornerRadius: 16))
}

struct PremiumAccounts: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var search = ""
    @State private var filter = "Todas"
    @State private var adding = false
    private let filters = ["Todas", "Crédito", "Débito", "Préstamo"]
    private var filtered: [FinanceAccount] {
        store.accounts.filter { a in
            (filter == "Todas" || a.kind.rawValue == filter) &&
            (search.isEmpty || a.name.localizedCaseInsensitiveContains(search) || bankName(a).localizedCaseInsensitiveContains(search))
        }
    }
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack { CMTitle(text: "Mis tarjetas"); Spacer(); Button { adding = true } label: { Image(systemName: "plus").font(.headline).foregroundStyle(Color.cmGreen).frame(width: 38, height: 38).background(Color.cmPanel, in: Circle()) } }
                    HStack { Image(systemName: "magnifyingglass"); TextField("Buscar banco o tarjeta...", text: $search) }.font(.subheadline).padding(13).background(Color.cmPanel, in: RoundedRectangle(cornerRadius: 14))
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(filters, id: \.self) { item in
                                Button { filter = item } label: {
                                    Text(item).font(.caption.bold()).padding(.horizontal, 15).padding(.vertical, 9)
                                        .background(filter == item ? Color.cmGreen : Color.cmPanel, in: Capsule())
                                        .foregroundStyle(filter == item ? .black : .white)
                                }
                            }
                        }
                    }
                    ForEach(filtered) { account in
                        NavigationLink(destination: AccountDetailView(accountID: account.id)) {
                            HStack(spacing: 12) {
                                CMBrandBadge(account: account, size: 46)
                                VStack(alignment: .leading, spacing: 7) {
                                    HStack { Text(account.name).font(.subheadline.bold()); Spacer(); Text(account.kind.rawValue).font(.caption2).foregroundStyle(.secondary) }
                                    Text("Usado: " + peso(account.used)).font(.caption).foregroundStyle(.white.opacity(0.72))
                                    Text("Disponible: " + peso(account.available)).font(.caption2).foregroundStyle(.white.opacity(0.58))
                                    GeometryReader { g in
                                        ZStack(alignment: .leading) {
                                            Capsule().fill(.white.opacity(0.12))
                                            Capsule().fill(account.utilization > 0.5 ? Color.orange : Color.cmGreen)
                                                .frame(width: g.size.width * min(1, account.utilization))
                                        }
                                    }.frame(height: 5)
                                }
                                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                            }.padding(14).background(Color.cmPanel, in: RoundedRectangle(cornerRadius: 17))
                        }.buttonStyle(.plain)
                    }
                    if filtered.isEmpty { ContentUnavailableView("Sin resultados", systemImage: "creditcard", description: Text("Agrega una tarjeta o cambia los filtros.")) }
                }.padding(18)
            }.background(Color.cmBackground.ignoresSafeArea())
                .toolbar(.hidden, for: .navigationBar)
                .sheet(isPresented: $adding) { AddAccountView().preferredColorScheme(.dark) }
        }
    }
}

struct PremiumWallet: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var selectedID: UUID?
    @State private var adding = false
    private var cards: [FinanceAccount] { store.accounts.filter { $0.kind != .loan } }
    private var current: FinanceAccount? { cards.first(where: { $0.id == selectedID }) ?? cards.first }
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        CMTitle(text: "Wallet")
                        Spacer()
                        Button { adding = true } label: {
                            Image(systemName: "plus").foregroundStyle(Color.cmGreen)
                                .font(.title3).frame(width: 38, height: 38)
                                .background(Color.cmPanel, in: Circle())
                        }
                    }
                    Text("Selecciona una tarjeta. Los préstamos se administran en Tarjetas.")
                        .font(.caption).foregroundStyle(.secondary)
                    if cards.isEmpty {
                        ContentUnavailableView("Sin tarjetas", systemImage: "creditcard",
                            description: Text("Agrega una tarjeta de crédito o débito."))
                    } else {
                        // Individual selectable rows avoid overlapping hit-testing areas.
                        VStack(spacing: 9) {
                            ForEach(cards) { account in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) { selectedID = account.id }
                                } label: {
                                    HStack(spacing: 12) {
                                        CMBrandBadge(account: account, size: 42)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(account.name).font(.subheadline.bold())
                                            Text(account.kind.rawValue).font(.caption).foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        if current?.id == account.id {
                                            Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.cmGreen)
                                        } else {
                                            Image(systemName: "circle").foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding(12)
                                    .background(current?.id == account.id ? Color.cmGreen.opacity(0.12) : Color.cmPanel,
                                                in: RoundedRectangle(cornerRadius: 15))
                                }.buttonStyle(.plain)
                            }
                        }
                        if let account = current {
                            CMCardFace(account: account, compact: false)
                                .id(account.id)
                            CMPanel {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text(account.name).font(.headline)
                                        Spacer()
                                        Text(account.kind.rawValue).font(.caption).foregroundStyle(.secondary)
                                    }
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text("Disponible").font(.caption).foregroundStyle(.secondary)
                                            Text(peso(account.available)).font(.headline).foregroundStyle(Color.cmGreen)
                                        }
                                        Spacer()
                                        VStack(alignment: .trailing) {
                                            Text("Utilizado").font(.caption).foregroundStyle(.secondary)
                                            Text(peso(account.used)).font(.headline)
                                        }
                                    }
                                    NavigationLink(destination: AccountDetailView(accountID: account.id)) {
                                        HStack {
                                            Text("Ver detalles, MSI y editar")
                                            Spacer()
                                            Image(systemName: "arrow.up.right")
                                        }.font(.subheadline.bold()).foregroundStyle(Color.cmGreen)
                                    }
                                }
                            }
                        }
                    }
                }.padding(18)
            }
            .background(Color.cmBackground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $adding) { AddAccountView() }
        }
    }
}

struct PremiumMovements: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var search = ""
    @State private var filter = "Todos"
    @State private var adding = false
    @State private var pendingDelete: UUID?
    private var filtered: [FinanceMovement] {
        store.movements.filter { m in
            (filter == "Todos" || (filter == "Compras" && !m.isPayment) || (filter == "Pagos" && m.isPayment)) &&
            (search.isEmpty || m.title.localizedCaseInsensitiveContains(search))
        }
    }
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack { CMTitle(text: "Movimientos"); Spacer(); Button { adding = true } label: { Image(systemName: "plus").foregroundStyle(Color.cmGreen).frame(width: 38, height: 38).background(Color.cmPanel, in: Circle()) }.disabled(store.accounts.isEmpty) }
                    HStack { Image(systemName: "magnifyingglass"); TextField("Buscar movimiento...", text: $search) }.font(.subheadline).padding(13).background(Color.cmPanel, in: RoundedRectangle(cornerRadius: 14))
                    HStack(spacing: 9) {
                        ForEach(["Todos", "Compras", "Pagos"], id: \.self) { item in
                            Button { filter = item } label: {
                                Text(item).font(.caption.bold()).padding(.horizontal, 17).padding(.vertical, 9)
                                    .foregroundStyle(filter == item ? .black : .white)
                                    .background(filter == item ? Color.cmGreen : Color.cmPanel, in: Capsule())
                            }
                        }
                    }
                    ForEach(filtered) { m in
                        movementRow(m, accounts: store.accounts)
                            .contextMenu { Button("Eliminar movimiento", role: .destructive) { pendingDelete = m.id } }
                    }
                    if filtered.isEmpty { ContentUnavailableView("Sin movimientos", systemImage: "arrow.left.arrow.right", description: Text("Registra tus compras y pagos manualmente.")) }
                }.padding(18)
            }.background(Color.cmBackground.ignoresSafeArea())
                .toolbar(.hidden, for: .navigationBar)
                .sheet(isPresented: $adding) { AddMovementView() }
                .confirmationDialog("¿Eliminar movimiento?", isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } })) {
                    Button("Eliminar", role: .destructive) { if let id = pendingDelete { store.deleteMovement(id) }; pendingDelete = nil }
                    Button("Cancelar", role: .cancel) { pendingDelete = nil }
                } message: { Text("El saldo registrado se ajustará al revertir este movimiento.") }
        }
    }
}

struct PremiumAnalytics: View {
    @EnvironmentObject private var store: FinanceStore
    private var ratio: Double { store.totalLimit > 0 ? store.totalUsedCredit / store.totalLimit : 0 }
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    CMTitle(text: "Análisis")
                    CMPanel {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Uso de crédito").font(.headline)
                            HStack(spacing: 24) {
                                ZStack {
                                    Circle().stroke(.white.opacity(0.10), lineWidth: 13)
                                    Circle().trim(from: 0, to: min(1, max(0, ratio)))
                                        .stroke(Color.cmGreen, style: StrokeStyle(lineWidth: 13, lineCap: .round))
                                        .rotationEffect(.degrees(-90))
                                    VStack { Text(pct(ratio)).font(.title2.bold()); Text("Uso global").font(.caption2).foregroundStyle(.secondary) }
                                }.frame(width: 135, height: 135)
                                VStack(alignment: .leading, spacing: 12) {
                                    stat("Crédito total", peso(store.totalLimit))
                                    stat("Utilizado", peso(store.totalUsedCredit))
                                    stat("Disponible", peso(max(0, store.totalLimit - store.totalUsedCredit)))
                                }
                            }
                        }
                    }
                    CMPanel {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Deuda por tarjeta").font(.headline)
                            if store.accounts.filter({ $0.kind != .debit }).isEmpty {
                                Text("Aún no hay datos para mostrar.").font(.caption).foregroundStyle(.secondary)
                            } else {
                                Chart(store.accounts.filter { $0.kind != .debit }) { a in
                                    BarMark(x: .value("Tarjeta", a.name), y: .value("Deuda", a.used))
                                        .foregroundStyle(Color.cmGreen.gradient)
                                        .cornerRadius(4)
                                }.chartXAxis { AxisMarks(values: .automatic) { AxisValueLabel() } }.frame(height: 185)
                            }
                        }
                    }
                    CMPanel {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Distribución por tarjeta").font(.headline)
                            ForEach(store.accounts.filter { $0.kind == .credit }) { a in
                                HStack(spacing: 10) {
                                    CMBrandBadge(account: a, size: 29)
                                    Text(a.name).font(.caption).frame(width: 90, alignment: .leading).lineLimit(1)
                                    GeometryReader { g in
                                        ZStack(alignment: .leading) {
                                            Capsule().fill(.white.opacity(0.10))
                                            Capsule().fill(a.utilization > 0.5 ? Color.orange : Color.cmGreen)
                                                .frame(width: g.size.width * min(1, a.utilization))
                                        }
                                    }.frame(height: 6)
                                    Text(pct(a.utilization)).font(.caption2).frame(width: 47, alignment: .trailing)
                                }
                            }
                        }
                    }
                    Text("El análisis usa únicamente los saldos que registras. No representa tu puntuación de Buró de Crédito.")
                        .font(.caption2).foregroundStyle(.secondary)
                }.padding(18)
            }.background(Color.cmBackground.ignoresSafeArea()).toolbar(.hidden, for: .navigationBar)
        }
    }
    private func stat(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) { Text(title).font(.caption2).foregroundStyle(.secondary); Text(value).font(.subheadline.bold()).lineLimit(1).minimumScaleFactor(0.7) }
    }
}

struct PremiumCalendar: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss
    @State private var month = Date()
    private let calendar = Calendar.current
    private var monthStart: Date { calendar.date(from: calendar.dateComponents([.year, .month], from: month)) ?? month }
    private var days: Int { calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 30 }
    private var offset: Int { (calendar.component(.weekday, from: monthStart) + 5) % 7 }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Button { shift(-1) } label: { Image(systemName: "chevron.left") }
                        Spacer()
                        Text(month.formatted(.dateTime.month(.wide).year()).capitalized).font(.headline)
                        Spacer()
                        Button { shift(1) } label: { Image(systemName: "chevron.right") }
                    }.foregroundStyle(.white)
                    let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(["L", "M", "M", "J", "V", "S", "D"].indices, id: \.self) { i in
                            Text(["L", "M", "M", "J", "V", "S", "D"][i]).font(.caption2.bold()).foregroundStyle(.secondary)
                        }
                        ForEach(0..<(offset + days), id: \.self) { index in
                            if index < offset { Color.clear.frame(height: 44) }
                            else {
                                let day = index - offset + 1
                                let hasPayment = store.accounts.contains { $0.kind != .debit && $0.paymentDay == day }
                                let hasCut = store.accounts.contains { $0.kind == .credit && $0.closingDay == day }
                                VStack(spacing: 4) {
                                    Text("\(day)").font(.subheadline.bold())
                                    HStack(spacing: 3) {
                                        if hasPayment { Circle().fill(Color.cmGreen).frame(width: 5, height: 5) }
                                        if hasCut { Circle().fill(Color.orange).frame(width: 5, height: 5) }
                                    }.frame(height: 5)
                                }.frame(maxWidth: .infinity).frame(height: 44)
                                    .background(hasPayment ? Color.cmGreen.opacity(0.14) : Color.cmPanel, in: RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                    HStack(spacing: 15) {
                        Label("Pago", systemImage: "circle.fill").foregroundStyle(Color.cmGreen)
                        Label("Corte", systemImage: "circle.fill").foregroundStyle(.orange)
                    }.font(.caption)
                    Text("Fechas registradas").font(.headline)
                    ForEach(store.accounts.filter { $0.kind != .debit }) { a in
                        HStack {
                            CMBrandBadge(account: a, size: 35)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(a.name).font(.subheadline.bold())
                                Text("Corte: \(a.closingDay) · Pago: \(a.paymentDay)").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                        }.padding(12).background(Color.cmPanel, in: RoundedRectangle(cornerRadius: 14))
                    }
                    Text("Las fechas 29, 30 y 31 pueden no existir en ciertos meses. Consulta tu estado de cuenta para confirmar vencimientos.")
                        .font(.caption2).foregroundStyle(.secondary)
                }.padding(18)
            }.background(Color.cmBackground.ignoresSafeArea())
                .navigationTitle("Calendario").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Cerrar") { dismiss() } } }
        }.preferredColorScheme(.dark)
    }
    private func shift(_ months: Int) { if let new = calendar.date(byAdding: .month, value: months, to: month) { month = new } }
}

struct PremiumMore: View {
    @State private var calendar = false
    @State private var wallet = false
    @State private var showExport = false
    @State private var showImport = false
    @State private var confirmImport = false
    @State private var selectedBackup: URL?
    @State private var importMessage: String?
    @State private var exportedBackup: URL?
    @State private var exportError: String?
    @EnvironmentObject private var store: FinanceStore
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    CMTitle(text: "Más")
                    Text("CARD MANAGER  /  PRO").font(.caption2.bold()).tracking(2).foregroundStyle(Color.cmGreen)
                    NavigationLink(destination: PremiumWallet()) { moreRow("Wallet", "square.stack.fill", "Tarjetas apiladas") }
                    Button { calendar = true } label: { moreRow("Calendario", "calendar", "Fechas de corte y pago") }
                    Button {
                        do {
                            exportedBackup = try store.exportBackup()
                            showExport = true
                        } catch { exportError = error.localizedDescription }
                    } label: { moreRow("Exportar respaldo", "square.and.arrow.up", "Incluye cuentas, movimientos y mensualidades") }
                    Button { showImport = true } label: {
                        moreRow("Importar respaldo", "square.and.arrow.down", "Restaurar un archivo JSON")
                    }
                    CMPanel {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Privacidad y almacenamiento").font(.headline)
                            Text("Tus datos se guardan localmente en este dispositivo. La app no accede a tus bancos, Apple Pay ni Apple Wallet. Guarda respaldos antes de reinstalar.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Text("Card Manager Pro · 1.6.0 · Vista previa de lanzamiento").font(.caption2).foregroundStyle(.secondary)
                }.padding(18)
            }.background(Color.cmBackground.ignoresSafeArea())
                .toolbar(.hidden, for: .navigationBar)
                .sheet(isPresented: $calendar) { PremiumCalendar() }
                .sheet(isPresented: $showExport) {
                    if let url = exportedBackup {
                        NavigationStack {
                            VStack(spacing: 22) {
                                Image(systemName: "externaldrive.fill").font(.largeTitle).foregroundStyle(Color.cmGreen)
                                Text("Respaldo preparado").font(.headline)
                                ShareLink(item: url) { Label("Guardar o compartir respaldo", systemImage: "square.and.arrow.up") }
                                Button("Cerrar") { showExport = false }
                            }.padding().navigationTitle("Exportar").navigationBarTitleDisplayMode(.inline)
                        }.preferredColorScheme(.dark)
                    }
                }
                .fileImporter(isPresented: $showImport, allowedContentTypes: [.json]) { result in
                    switch result {
                    case .success(let url): selectedBackup = url; confirmImport = true
                    case .failure(let error): importMessage = error.localizedDescription
                    }
                }
                .confirmationDialog("¿Reemplazar todos los datos?", isPresented: $confirmImport, titleVisibility: .visible) {
                    Button("Importar y reemplazar", role: .destructive) {
                        guard let url = selectedBackup else { return }
                        do { try store.importBackup(from: url); importMessage = "Respaldo restaurado correctamente." }
                        catch { importMessage = error.localizedDescription }
                        selectedBackup = nil
                    }
                    Button("Cancelar", role: .cancel) { selectedBackup = nil }
                } message: {
                    Text("Se reemplazarán todas las cuentas, movimientos y planes de pago actuales. Exporta primero un respaldo de seguridad.")
                }
                .alert("Respaldo", isPresented: Binding(get: { importMessage != nil || exportError != nil }, set: { if !$0 { importMessage = nil; exportError = nil } })) {
                    Button("Aceptar") { importMessage = nil; exportError = nil }
                } message: { Text(importMessage ?? exportError ?? "") }
        }
    }
    private func moreRow(_ title: String, _ symbol: String, _ subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol).foregroundStyle(Color.cmGreen).frame(width: 35, height: 35).background(Color.cmGreen.opacity(0.09), in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 4) { Text(title).font(.subheadline.bold()); Text(subtitle).font(.caption).foregroundStyle(.secondary) }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
        }.padding(15).foregroundStyle(.white).background(Color.cmPanel, in: RoundedRectangle(cornerRadius: 16))
    }
}
