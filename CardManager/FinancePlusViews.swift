import SwiftUI

private func cmMoney(_ amount: Double) -> String { amount.formatted(.currency(code: "MXN")) }
private func cmPercent(_ amount: Double) -> String { amount.formatted(.percent.precision(.fractionLength(1))) }

// This is an educational utilization indicator, NOT a credit bureau score.
func creditTone(_ ratio: Double) -> Color {
    if ratio <= 0.30 { return .cmGreen }
    if ratio <= 0.60 { return .yellow }
    return .orange
}
func creditStatus(_ ratio: Double) -> String {
    if ratio <= 0.30 { return "Dentro de referencia" }
    if ratio <= 0.60 { return "Por encima de referencia" }
    return "Utilización alta" 
}

struct CreditHealthView: View {
    @EnvironmentObject private var store: FinanceStore
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Salud crediticia").font(.title.bold())
                Text("Análisis orientativo de utilización de crédito, no un score bancario ni de Buró.")
                    .font(.caption).foregroundStyle(.secondary)
                CMPanel {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Utilización total").font(.headline)
                            Spacer()
                            Text(cmPercent(store.creditUtilization)).font(.title2.bold()).foregroundStyle(creditTone(store.creditUtilization))
                        }
                        ProgressView(value: min(1, max(0, store.creditUtilization))).tint(creditTone(store.creditUtilization))
                        Text(creditStatus(store.creditUtilization)).font(.subheadline.bold())
                        Text("Límite: \(cmMoney(store.totalLimit)) · Utilizado: \(cmMoney(store.totalUsedCredit))")
                            .font(.caption).foregroundStyle(.secondary)
                        if store.totalLimit > 0 && store.amountToTarget > 0 {
                            Text("Para acercarte al 30%, tendrías que reducir el saldo aproximadamente \(cmMoney(store.amountToTarget)).")
                                .font(.subheadline)
                        }
                    }
                }
                Text("Por tarjeta").font(.headline)
                ForEach(store.creditAccounts) { account in
                    NavigationLink(destination: AccountDetailView(accountID: account.id)) {
                        CMPanel {
                            VStack(alignment: .leading, spacing: 9) {
                                HStack {
                                    CMBrandBadge(account: account, size: 34)
                                    Text(account.name).font(.headline)
                                    Spacer()
                                    Text(cmPercent(account.utilization)).font(.headline).foregroundStyle(creditTone(account.utilization))
                                }
                                ProgressView(value: min(1, max(0, account.utilization))).tint(creditTone(account.utilization))
                                Text(creditStatus(account.utilization)).font(.caption).foregroundStyle(.secondary)
                                if account.limit > 0 && account.utilization > 0.30 {
                                    Text("Reducción aproximada al 30%: \(cmMoney(account.used - account.limit * 0.30))")
                                        .font(.caption)
                                }
                            }
                        }
                    }.buttonStyle(.plain)
                }
                CMPanel {
                    VStack(alignment: .leading, spacing: 9) {
                        Label("Qué significa", systemImage: "info.circle").font(.headline)
                        Text("Verde: hasta 30%; amarillo: más de 30% a 60%; naranja: más de 60%. Son rangos de referencia configurados para visualizar utilización, no criterios oficiales universales de aprobación.")
                        Text("La puntualidad, la deuda total, la antigüedad y otros factores también importan. La salud financiera requiere ingresos, gastos y obligaciones reales; con solo saldos no puede calcularse de forma fiable.")
                    }.font(.caption).foregroundStyle(.secondary)
                }
            }.padding(18)
        }.background(Color.cmBackground.ignoresSafeArea())
            .navigationTitle("Utilización")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct DebitAccountsView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var adding = false
    @State private var transfer = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Mi dinero").font(.title.bold())
                CMPanel {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Saldo propio disponible", systemImage: "banknote.fill").foregroundStyle(Color.cmGreen)
                        Text(cmMoney(store.debitBalance)).font(.system(size: 29, weight: .bold, design: .rounded)).foregroundStyle(Color.cmGreen)
                        Text("Total de cuentas de débito. No incluye líneas de crédito ni préstamos.").font(.caption).foregroundStyle(.secondary)
                    }
                }
                HStack {
                    Text("Cuentas de débito").font(.headline)
                    Spacer()
                    Button { adding = true } label: { Label("Agregar", systemImage: "plus") }.foregroundStyle(Color.cmGreen)
                }
                ForEach(store.debitAccounts) { account in
                    NavigationLink(destination: AccountDetailView(accountID: account.id)) {
                        CMPanel {
                            HStack(spacing: 12) {
                                CMBrandBadge(account: account, size: 45)
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(account.name).font(.headline)
                                    Text("Saldo disponible").font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(cmMoney(account.available)).font(.subheadline.bold()).foregroundStyle(Color.cmGreen)
                                    .minimumScaleFactor(0.7).lineLimit(1)
                            }
                        }
                    }.buttonStyle(.plain)
                }
                if store.debitAccounts.count >= 2 {
                    Button { transfer = true } label: {
                        Label("Transferir entre mis cuentas", systemImage: "arrow.left.arrow.right")
                            .frame(maxWidth: .infinity).padding(15)
                            .background(Color.cmPanel, in: RoundedRectangle(cornerRadius: 16))
                    }.foregroundStyle(Color.cmGreen)
                }
                Text("Los movimientos de débito son manuales. Una transferencia propia mueve saldo entre cuentas y no aumenta el dinero total.")
                    .font(.caption).foregroundStyle(.secondary)
            }.padding(18)
        }.background(Color.cmBackground.ignoresSafeArea())
            .navigationTitle("Débito").navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $adding) { AddAccountView() }
            .sheet(isPresented: $transfer) { DebitTransferView() }
    }
}

struct DebitTransferView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss
    @State private var source: UUID?
    @State private var destination: UUID?
    @State private var amount = ""
    @State private var confirm = false
    private var number: Double { Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0 }
    private var valid: Bool {
        guard let a = source, let b = destination, a != b,
              let account = store.debitAccounts.first(where: { $0.id == a }) else { return false }
        return number > 0 && number <= account.available
    }
    var body: some View {
        NavigationStack {
            Form {
                Picker("Origen", selection: $source) {
                    Text("Seleccionar").tag(nil as UUID?)
                    ForEach(store.debitAccounts) { account in Text(account.name).tag(Optional(account.id)) }
                }
                Picker("Destino", selection: $destination) {
                    Text("Seleccionar").tag(nil as UUID?)
                    ForEach(store.debitAccounts) { account in Text(account.name).tag(Optional(account.id)) }
                }
                TextField("Importe MXN", text: $amount).keyboardType(.decimalPad)
                Text("No es un ingreso ni un gasto nuevo: el dinero total se conserva.")
                    .font(.caption).foregroundStyle(.secondary)
                Button("Transferir") { confirm = true }.disabled(!valid)
            }.navigationTitle("Transferencia")
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } } }
                .confirmationDialog("Confirmar transferencia", isPresented: $confirm) {
                    Button("Confirmar \(cmMoney(number))") {
                        if valid, let a = source, let b = destination {
                            store.transfer(from: a, to: b, amount: number, date: .now)
                            dismiss()
                        }
                    }
                    Button("Cancelar", role: .cancel) { }
                } message: { Text("Se descontará de la cuenta origen y se sumará a la cuenta destino.") }
        }.preferredColorScheme(.dark)
    }
}

struct LoanOverviewView: View {
    @EnvironmentObject private var store: FinanceStore
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 17) {
                Text("Mis préstamos").font(.title.bold())
                CMPanel {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Deuda registrada pendiente").font(.caption).foregroundStyle(.secondary)
                        Text(cmMoney(store.totalLoanDebt)).font(.title.bold())
                        HStack { Text("Monto original registrado"); Spacer(); Text(cmMoney(store.totalLoanOriginal)) }
                        HStack { Text("Diferencia estimada"); Spacer(); Text(cmMoney(store.totalLoanRepaid)).foregroundStyle(Color.cmGreen) }
                        Text("La diferencia no representa necesariamente capital amortizado: pueden existir intereses, cargos o ajustes.")
                            .font(.caption2).foregroundStyle(.secondary)
                    }.font(.subheadline)
                }
                ForEach(store.loanAccounts) { account in
                    NavigationLink(destination: AccountDetailView(accountID: account.id)) {
                        CMPanel {
                            HStack(spacing: 12) {
                                CMBrandBadge(account: account, size: 43)
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(account.name).font(.headline)
                                    Text("Pendiente: \(cmMoney(account.used))").font(.subheadline)
                                    Text("\(store.plans(for: account.id).count) planes registrados")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(.secondary)
                            }
                        }
                    }.buttonStyle(.plain)
                }
            }.padding(18)
        }.background(Color.cmBackground.ignoresSafeArea())
            .navigationTitle("Préstamos").navigationBarTitleDisplayMode(.inline)
    }
}

struct InstallmentScheduleView: View {
    @EnvironmentObject private var store: FinanceStore
    let planID: UUID
    @State private var editing: PaymentScheduleOverride?
    private var plan: InstallmentPlan? { store.plans.first(where: { $0.id == planID }) }
    var body: some View {
        ScrollView {
            if let plan = plan {
                let entries = store.schedule(for: plan)
                let paid = entries.reduce(0) { $0 + $1.paidAmount }
                let total = entries.reduce(0) { $0 + $1.amount }
                VStack(alignment: .leading, spacing: 16) {
                    Text(plan.title).font(.title2.bold())
                    CMPanel {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading) { Text("Pagado registrado").font(.caption).foregroundStyle(.secondary); Text(cmMoney(paid)).font(.headline).foregroundStyle(Color.cmGreen) }
                                Spacer()
                                VStack(alignment: .trailing) { Text("Por pagar").font(.caption).foregroundStyle(.secondary); Text(cmMoney(max(0,total-paid))).font(.headline) }
                            }
                            ProgressView(value: paid, total: max(1,total)).tint(.cmGreen)
                            Text("\(entries.filter { $0.paidAmount >= $0.amount - 0.005 }.count) de \(entries.count) cuotas completas")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    ForEach(entries) { entry in
                        Button { editing = entry } label: {
                            CMPanel {
                                HStack(spacing: 12) {
                                    Image(systemName: entry.paidAmount >= entry.amount - 0.005 ? "checkmark.circle.fill" : "circle.dotted")
                                        .font(.title2).foregroundStyle(entry.paidAmount >= entry.amount - 0.005 ? Color.cmGreen : .secondary)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Cuota \(entry.installment) · \(entry.dueDate.formatted(date: .abbreviated, time: .omitted))")
                                            .font(.subheadline.bold())
                                        Text("Pagado \(cmMoney(entry.paidAmount)) de \(cmMoney(entry.amount))")
                                            .font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "pencil.circle").foregroundStyle(Color.cmGreen)
                                }
                            }
                        }.buttonStyle(.plain)
                    }
                    Text("Los cambios de cuota no ajustan automáticamente el saldo de la tarjeta o préstamo. Registra por separado el movimiento real para mantener el balance correcto.")
                        .font(.caption).foregroundStyle(.secondary)
                }.padding(18)
            } else { ContentUnavailableView("Plan no encontrado", systemImage: "calendar.badge.exclamationmark") }
        }.background(Color.cmBackground.ignoresSafeArea())
            .navigationTitle("Calendario de cuotas").navigationBarTitleDisplayMode(.inline)
            .sheet(item: $editing) { item in InstallmentEditorView(entry: item) }
    }
}

struct InstallmentEditorView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss
    let entry: PaymentScheduleOverride
    @State private var date: Date
    @State private var amount: String
    @State private var paid: String
    @State private var confirm = false
    init(entry: PaymentScheduleOverride) {
        self.entry = entry
        _date = State(initialValue: entry.dueDate)
        _amount = State(initialValue: String(entry.amount))
        _paid = State(initialValue: String(entry.paidAmount))
    }
    private var total: Double { Double(amount.replacingOccurrences(of: ",", with: ".")) ?? -1 }
    private var paidValue: Double { Double(paid.replacingOccurrences(of: ",", with: ".")) ?? -1 }
    private var valid: Bool { total > 0 && paidValue >= 0 && paidValue <= total }
    var body: some View {
        NavigationStack {
            Form {
                Section("Mensualidad \(entry.installment)") {
                    DatePicker("Vencimiento", selection: $date, displayedComponents: .date)
                    TextField("Monto programado", text: $amount).keyboardType(.decimalPad)
                    TextField("Monto pagado (permite pagos parciales)", text: $paid).keyboardType(.decimalPad)
                    Text("Puedes corregir una cuota anterior o registrar un pago parcial. No se cambia ninguna otra cuota.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Button("Revisar y guardar") { confirm = true }.disabled(!valid)
            }.navigationTitle("Editar cuota")
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } } }
                .confirmationDialog("Confirmar cambios", isPresented: $confirm) {
                    Button("Guardar cuota \(entry.installment)") {
                        guard valid else { return }
                        var value = entry
                        value.dueDate = date
                        value.amount = total
                        value.paidAmount = paidValue
                        value.paidDate = paidValue > 0 ? .now : nil
                        store.saveInstallment(value)
                        dismiss()
                    }
                    Button("Cancelar", role: .cancel) { }
                } message: { Text("Importe: \(cmMoney(total)). Pagado: \(cmMoney(paidValue)). Solo se modificará esta mensualidad.") }
        }.preferredColorScheme(.dark)
    }
}
