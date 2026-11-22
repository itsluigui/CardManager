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
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 22)
                .fill(LinearGradient(colors: [BankCatalog.color(for: account.bankID).opacity(0.9), .black], startPoint: .topLeading, endPoint: .bottomTrailing))
            MarketBackdrop().clipShape(RoundedRectangle(cornerRadius: 22)).opacity(0.4)
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Text(account.bankID.isEmpty ? account.name : BankCatalog.name(for: account.bankID))
                        .font(.title2.bold())
                    Spacer()
                    Text(account.network).font(.caption.bold())
                }
                Spacer()
                Text(account.kind.rawValue.uppercased()).font(.caption).tracking(2)
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Disponible").font(.caption)
                        Text(account.available.formatted(.currency(code: "MXN"))).font(.title3.bold())
                    }
                    Spacer()
                    Image(systemName: "wave.3.right").font(.title2)
                }
            }.padding(22).foregroundStyle(.white)
        }
        .frame(height: 204)
        .accessibilityElement(children: .combine)
    }
}
struct WalletView: View {
    @EnvironmentObject private var store: FinanceStore
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(store.accounts) { account in
                        NavigationLink(destination: AccountDetailView(accountID: account.id)) {
                            WalletCard(account: account)
                        }.buttonStyle(.plain)
                    }
                    if store.accounts.isEmpty {
                        ContentUnavailableView("Wallet vacío", systemImage: "creditcard", description: Text("Agrega tarjetas desde la pestaña Tarjetas."))
                    }
                }.padding()
            }.navigationTitle("Wallet")
        }
    }
}
