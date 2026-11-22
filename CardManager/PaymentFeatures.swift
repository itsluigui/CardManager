import SwiftUI

private func mxn(_ amount: Double) -> String { amount.formatted(.currency(code: "MXN")) }

struct PaymentCountdown: View {
    let date: Date
    private var days: Int { Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: Calendar.current.startOfDay(for: date)).day ?? 0 }
    var body: some View {
        Label(days < 0 ? "Venció hace \(-days) días" : days == 0 ? "Vence hoy" : days == 1 ? "Vence mañana" : "Faltan \(days) días", systemImage: "clock")
            .font(.caption.bold()).foregroundStyle(days < 0 ? .red : days <= 3 ? .orange : Color.cmGreen)
    }
}

struct PlanRow: View {
    @EnvironmentObject private var store: FinanceStore
    let plan: InstallmentPlan
    @State private var editing = false
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.title).font(.subheadline.bold())
                    Text(plan.isInterestFree ? "Meses sin intereses" : "Plan de pagos / préstamo").font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
                Text(mxn(plan.monthlyAmount)).font(.subheadline.bold()).foregroundStyle(Color.cmGreen)
            }
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(plan.paidMonths) de \(plan.totalMonths) mensualidades")
                    Text("Pagado estimado: \(mxn(Double(plan.paidMonths) * plan.monthlyAmount))")
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text("Restan \(plan.remainingMonths) meses")
                    Text("Pendiente estimado: \(mxn(plan.remainingBalance))")
                }
            }.font(.caption2).foregroundStyle(.secondary)
            ProgressView(value: Double(plan.paidMonths), total: Double(max(plan.totalMonths, 1))).tint(.cmGreen)
            HStack {
                if plan.isFinished { Text("Liquidado").foregroundStyle(Color.cmGreen).font(.caption.bold()) }
                else { PaymentCountdown(date: plan.nextPaymentDate) }
                Spacer()
                Button("Editar") { editing = true }
                    .font(.caption.bold()).foregroundStyle(Color.cmGreen)
                if !plan.isFinished {
                    Button("Marcar cuota pagada") { store.markInstallmentPaid(plan.id) }
                        .font(.caption.bold()).foregroundStyle(Color.cmGreen)
                }
            }
        }.padding(14).background(Color.cmPanel, in: RoundedRectangle(cornerRadius: 16))
            .sheet(isPresented: $editing) { EditPlanView(plan: plan) }
    }
}

struct AccountPlansSection: View {
    @EnvironmentObject private var store: FinanceStore
    let account: FinanceAccount
    @State private var adding = false
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(account.kind == .loan ? "Mensualidades del préstamo" : "Compras a meses y MSI").font(.headline)
                Spacer()
                Button { adding = true } label: { Label("Agregar", systemImage: "plus.circle.fill").font(.caption.bold()) }.tint(.cmGreen)
            }
            if store.plans(for: account.id).isEmpty {
                Text("Sin planes registrados. Agrega cada compra a MSI o el calendario de tu préstamo.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            ForEach(store.plans(for: account.id)) { plan in
                PlanRow(plan: plan)
                    .contextMenu { Button("Eliminar plan", role: .destructive) { store.deletePlan(plan.id) } }
            }
            Text("Marcar una cuota como pagada actualiza el plan, pero no cambia automáticamente el saldo de la cuenta. Registra también el pago en Movimientos para actualizar la deuda.")
                .font(.caption2).foregroundStyle(.secondary)
        }
        .sheet(isPresented: $adding) { AddPlanView(account: account) }
    }
}

struct AddPlanView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: FinanceStore
    let account: FinanceAccount
    @State private var title = ""
    @State private var principal = ""
    @State private var months = 12
    @State private var paid = 0
    @State private var monthly = ""
    @State private var nextDate = Date()
    @State private var noInterest = true
    private func value(_ string: String) -> Double? { Double(string.replacingOccurrences(of: ",", with: ".")) }
    var body: some View {
        NavigationStack {
            Form {
                Section("Detalle") {
                    TextField(account.kind == .loan ? "Nombre del préstamo" : "Producto o compra", text: $title)
                    TextField("Monto original", text: $principal).keyboardType(.decimalPad)
                    Toggle("Sin intereses (MSI)", isOn: $noInterest).disabled(account.kind == .loan)
                }
                Section("Mensualidades") {
                    Stepper("Total: \(months) meses", value: $months, in: 1...120)
                    Stepper("Ya pagadas: \(paid)", value: $paid, in: 0...months)
                    TextField("Pago mensual", text: $monthly).keyboardType(.decimalPad)
                    DatePicker("Próximo vencimiento", selection: $nextDate, displayedComponents: .date)
                    if let amount = value(monthly), amount > 0 { Text("Saldo estimado pendiente: \(mxn(Double(months - paid) * amount))").font(.caption) }
                }
                Section { Text("Registra la mensualidad indicada por tu banco o contrato. No se calculan intereses, comisiones ni pagos automáticamente.").font(.caption).foregroundStyle(.secondary) }
            }
            .navigationTitle("Nuevo plan")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        guard let original = value(principal), let amount = value(monthly) else { return }
                        store.addPlan(InstallmentPlan(accountID: account.id, title: title.trimmingCharacters(in: .whitespacesAndNewlines), principal: original, totalMonths: months, paidMonths: paid, monthlyAmount: amount, nextPaymentDate: nextDate, isInterestFree: account.kind != .loan && noInterest))
                        dismiss()
                    }.disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (value(principal) ?? 0) <= 0 || (value(monthly) ?? 0) <= 0)
                }
            }
        }.preferredColorScheme(.dark)
    }
}


struct EditPlanView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: FinanceStore
    let plan: InstallmentPlan
    @State private var title: String
    @State private var months: Int
    @State private var paid: Int
    @State private var monthly: String
    @State private var due: Date

    init(plan: InstallmentPlan) {
        self.plan = plan
        _title = State(initialValue: plan.title)
        _months = State(initialValue: plan.totalMonths)
        _paid = State(initialValue: plan.paidMonths)
        _monthly = State(initialValue: String(plan.monthlyAmount))
        _due = State(initialValue: plan.nextPaymentDate)
    }
    var body: some View {
        NavigationStack {
            Form {
                TextField("Concepto", text: $title)
                Stepper("Total de meses: \(months)", value: $months, in: 1...120)
                Stepper("Meses pagados: \(paid)", value: $paid, in: 0...months)
                TextField("Mensualidad", text: $monthly).keyboardType(.decimalPad)
                DatePicker("Próximo vencimiento", selection: $due, displayedComponents: .date)
                Text("El avance es manual y no cambia el saldo de la cuenta.").font(.caption).foregroundStyle(.secondary)
            }
            .navigationTitle("Editar plan")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        guard let amount = Double(monthly.replacingOccurrences(of: ",", with: ".")), amount > 0 else { return }
                        var updated = plan
                        updated.title = title
                        updated.totalMonths = months
                        updated.paidMonths = min(paid, months)
                        updated.monthlyAmount = amount
                        updated.nextPaymentDate = due
                        store.updatePlan(updated)
                        dismiss()
                    }.disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }.preferredColorScheme(.dark)
    }
}
