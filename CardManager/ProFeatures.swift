import SwiftUI
import UniformTypeIdentifiers

struct BankEntry: Identifiable {
    let id: String
    let name: String
    let color: Color
}
enum CardNetworks {
    static let names = ["Sin especificar", "Visa", "Mastercard", "American Express", "Otro"]
}
enum BankCatalog {
    static let banks: [BankEntry] = [
        .init(id: "revolut", name: "Revolut", color: .gray),
        .init(id: "nu", name: "Nu", color: .purple),
        .init(id: "rappi", name: "RappiCard", color: .red),
        .init(id: "mercadopago", name: "Mercado Pago", color: .blue),
        .init(id: "plata", name: "Plata", color: .gray),
        .init(id: "bbva", name: "BBVA", color: .blue),
        .init(id: "banamex", name: "Banamex", color: .red),
        .init(id: "santander", name: "Santander", color: .red),
        .init(id: "hsbc", name: "HSBC", color: .red),
        .init(id: "banorte", name: "Banorte", color: .red),
        .init(id: "klar", name: "Klar", color: .indigo),
        .init(id: "stori", name: "Stori", color: .pink),
        .init(id: "amex", name: "American Express", color: .blue),
        .init(id: "other", name: "Otro banco", color: .gray)
    ]
    static func name(for id: String) -> String { banks.first(where: { $0.id == id })?.name ?? "Sin seleccionar" }
    static func color(for id: String) -> Color { banks.first(where: { $0.id == id })?.color ?? .green }
}
struct BankSelector: View {
    @Binding var selection: String
    @State private var search = ""
    var body: some View {
        NavigationLink {
            List {
                ForEach(BankCatalog.banks.filter { search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) }) { bank in
                    Button {
                        selection = bank.id
                    } label: {
                        HStack {
                            RoundedRectangle(cornerRadius: 8).fill(bank.color).frame(width: 30, height: 30)
                            Text(bank.name).foregroundStyle(.primary)
                            Spacer()
                            if selection == bank.id { Image(systemName: "checkmark").foregroundStyle(.green) }
                        }
                    }
                }
            }
            .searchable(text: $search, prompt: "Buscar banco o emisor")
            .navigationTitle("Buscar banco")
        } label: {
            LabeledContent("Banco / emisor", value: BankCatalog.name(for: selection))
        }
    }
}
struct MarketBackdrop: View {
    private let values: [CGFloat] = [0.55,0.39,0.48,0.23,0.33,0.16,0.30,0.19,0.12,0.26,0.08]
    var body: some View {
        GeometryReader { g in
            ZStack {
                LinearGradient(colors: [.green.opacity(0.17), .black], startPoint: .topLeading, endPoint: .bottomTrailing)
                Path { path in
                    for (index, value) in values.enumerated() {
                        let point = CGPoint(x: g.size.width * CGFloat(index) / CGFloat(values.count - 1), y: g.size.height * value)
                        if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
                    }
                }.stroke(.green.opacity(0.6), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                HStack {
                    Text("+2.45%  ↗").foregroundStyle(.green.opacity(0.5))
                    Spacer()
                    Text("−0.83%  ↘").foregroundStyle(.red.opacity(0.45))
                }.font(.caption2.monospacedDigit()).padding()
            }
        }.accessibilityLabel("Decoración bursátil, sin cotizaciones reales")
    }
}
struct WalletCard: View {
    let account: FinanceAccount
    private var brand: String { account.bankID.isEmpty ? account.name : BankCatalog.name(for: account.bankID) }
    private var palette: [Color] {
        switch account.bankID {
        case "nu": return [Color(red: 0.43,green: 0.15,blue: 0.69), Color(red: 0.15,green: 0.04,blue: 0.27)]
        case "rappi": return [Color(red: 0.25,green: 0.26,blue: 0.29), .black]
        case "mercadopago": return [Color(red: 0.08,green: 0.34,blue: 0.74), Color(red: 0.02,green: 0.11,blue: 0.30)]
        case "bbva": return [Color(red: 0.03,green: 0.25,blue: 0.58), Color(red: 0.01,green: 0.08,blue: 0.20)]
        case "plata": return [Color(red: 0.37,green: 0.39,blue: 0.43), Color(red: 0.08,green: 0.09,blue: 0.10)]
        case "revolut": return [Color(red: 0.24,green: 0.27,blue: 0.35), Color(red: 0.03,green: 0.04,blue: 0.07)]
        default: return [Color(red: 0.16,green: 0.26,blue: 0.17), Color(red: 0.025,green: 0.07,blue: 0.04)]
        }
    }
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 24).fill(LinearGradient(colors: palette, startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle().stroke(.white.opacity(0.08), lineWidth: 40).frame(width: 210, height: 210).offset(x: 210, y: -90)
            Circle().fill(.white.opacity(0.04)).frame(width: 180, height: 180).blur(radius: 18).offset(x: 180, y: 80)
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(brand).font(.system(size: 25, weight: .heavy, design: .rounded)).tracking(-0.7)
                        Text("CARD MANAGER  •  \(account.kind.rawValue.uppercased())").font(.system(size: 9, weight: .semibold)).tracking(1.5).foregroundStyle(.white.opacity(0.65))
                    }
                    Spacer()
                    Image(systemName: "wave.3.right").font(.title3).rotationEffect(.degrees(90)).foregroundStyle(.white.opacity(0.85))
                }
                Spacer()
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 4).fill(LinearGradient(colors: [.yellow.opacity(0.8), .white.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 35, height: 26).overlay(RoundedRectangle(cornerRadius: 4).stroke(.black.opacity(0.2)))
                    Spacer()
                    Text(account.network == "Sin especificar" ? "" : account.network.uppercased()).font(.caption.bold()).italic()
                }
                Spacer().frame(height: 15)
                Text("DISPONIBLE").font(.system(size: 9, weight: .semibold)).tracking(2).foregroundStyle(.white.opacity(0.7))
                Text(account.available.formatted(.currency(code: "MXN"))).font(.system(size: 25, weight: .bold, design: .rounded)).minimumScaleFactor(0.6).lineLimit(1)
            }.padding(24).foregroundStyle(.white)
        }
        .frame(height: 215)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.16), lineWidth: 1))
        .shadow(color: palette[0].opacity(0.22), radius: 16, y: 10)
        .accessibilityElement(children: .combine)
    }
}

struct WalletView: View {
    @EnvironmentObject private var store: FinanceStore
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("TU COLECCIÓN").font(.caption2.bold()).tracking(2.5).foregroundStyle(.green)
                        Text("Wallet").font(.largeTitle.bold()).foregroundStyle(.white)
                        Text("Todas tus tarjetas, en un solo lugar.").font(.subheadline).foregroundStyle(.white.opacity(0.55))
                    }.padding(.bottom, 5)
                    ForEach(store.accounts) { account in
                        NavigationLink(destination: AccountDetailView(accountID: account.id)) {
                            WalletCard(account: account)
                        }.buttonStyle(.plain)
                    }
                    if store.accounts.isEmpty {
                        ContentUnavailableView("Wallet vacío", systemImage: "creditcard", description: Text("Agrega tarjetas desde la pestaña Tarjetas."))
                    }
                }.padding()
            }
            .background(Color(red: 0.035, green: 0.045, blue: 0.04).ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}
