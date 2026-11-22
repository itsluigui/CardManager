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

// The detail screen uses one presentation owner for ALL plan actions.
// Never attach separate sheets or confirmation dialogs to rows inside a List.
private enum PlanSheet: Identifiable {
    case add(UUID)
    case edit(UUID)
    var id: String {
        switch self { case .add(let id): return "add-\(id.uuidString)"; case .edit(let id): return "edit-\(id.uuidString)" }
    }
}

struct PlanRow: View {
    @EnvironmentObject private var store: FinanceStore
    let plan: InstallmentPlan
    var body: some View {
        let entries = store.schedule(for: plan)
        let paidTotal = entries.reduce(0) { $0 + $1.paidAmount }
        let scheduledTotal = entries.reduce(0) { $0 + $1.amount }
        let finishedCount = entries.filter { $0.paidAmount >= $0.amount - 0.005 }.count
        let nextDue = entries.first(where: { $0.paidAmount < $0.amount - 0.005 })?.dueDate
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.title).font(.subheadline.bold())
                    Text(plan.isInterestFree ? "Meses sin intereses" : "Plan de pagos / préstamo")
                        .font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
                Text(mxn(plan.monthlyAmount)).font(.subheadline.bold()).foregroundStyle(Color.cmGreen)
            }
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(finishedCount) de \(entries.count) mensualidades")
                    Text("Pagado registrado: \(mxn(paidTotal))")
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text("Restan \(entries.count - finishedCount) cuotas")
                    Text("Por pagar: \(mxn(max(0, scheduledTotal - paidTotal)))")
                }
            }.font(.caption2).foregroundStyle(.secondary)
            ProgressView(value: paidTotal, total: max(1, scheduledTotal)).tint(.cmGreen)
            if finishedCount == entries.count { Text("Liquidado").font(.caption.bold()).foregroundStyle(Color.cmGreen) }
            else if let due = nextDue { PaymentCountdown(date: due) }
        }.padding(14).frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cmPanel, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct PlanTimelineTarget: Identifiable { let id: UUID }

struct AccountPlansSection: View {
    @EnvironmentObject private var store: FinanceStore
    let account: FinanceAccount
    @State private var activeSheet: PlanSheet?
    @State private var paymentPlanID: UUID?
    @State private var deletionID: UUID?
    @State private var timelineID: UUID?
    private var accountPlans: [InstallmentPlan] { store.plans(for: account.id) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(account.kind == .loan ? "Mensualidades del préstamo" : "Compras a meses y MSI").font(.headline)
                Spacer()
                Button { activeSheet = .add(account.id) } label: {
                    Label("Agregar", systemImage: "plus.circle.fill").font(.subheadline.bold())
                }.buttonStyle(.plain).foregroundStyle(Color.cmGreen)
            }
            if accountPlans.isEmpty {
                Text("Sin planes registrados. Agrega cada compra a MSI o el calendario de tu préstamo.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            ForEach(accountPlans) { plan in
                VStack(alignment: .leading, spacing: 9) {
                    PlanRow(plan: plan)
                    HStack(spacing: 18) {
                        Button { activeSheet = .edit(plan.id) } label: {
                            Label("Editar", systemImage: "pencil")
                        }.buttonStyle(.plain)
                        Button { timelineID = plan.id } label: {
                            Label("Calendario visual", systemImage: "calendar")
                        }.buttonStyle(.plain)
                        Spacer(minLength: 0)
                        Button(role: .destructive) { deletionID = plan.id } label: {
                            Image(systemName: "trash")
                        }.buttonStyle(.plain)
                    }
                    .font(.caption.bold()).foregroundStyle(Color.cmGreen)
                    .padding(.horizontal, 12).padding(.bottom, 10)
                }
                .background(Color.cmPanel.opacity(0.4), in: RoundedRectangle(cornerRadius: 16))
                .id(plan.id)
            }
            Text("Los pagos de mensualidades son manuales y no modifican automáticamente la deuda. Registra también el movimiento correspondiente.")
                .font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(item: Binding<PlanTimelineTarget?>(
            get: { timelineID.map { PlanTimelineTarget(id: $0) } },
            set: { timelineID = $0?.id }
        )) { target in InstallmentScheduleView(planID: target.id) }
        .sheet(item: $activeSheet) { target in
            switch target {
            case .add:
                AddPlanView(account: account)
            case .edit(let id):
                if let plan = store.plans.first(where: { $0.id == id && $0.accountID == account.id }) {
                    EditPlanView(plan: plan)
                } else { Text("Plan no encontrado") }
            }
        }
        .alert("Confirmar pago", isPresented: Binding(
            get: { paymentPlanID != nil },
            set: { if !$0 { paymentPlanID = nil } }
        )) {
            Button("Cancelar", role: .cancel) { paymentPlanID = nil }
            Button("Sí, registrar una mensualidad") {
                if let id = paymentPlanID { store.markInstallmentPaid(id) }
                paymentPlanID = nil
            }
        } message: {
            if let id = paymentPlanID, let plan = store.plans.first(where: { $0.id == id }) {
                Text("¿Registrar un pago de \(mxn(plan.monthlyAmount)) para \(plan.title)? No se modificará automáticamente el saldo de la cuenta.")
            } else { Text("Selecciona un plan válido.") }
        }
        .confirmationDialog("Eliminar plan", isPresented: Binding(
            get: { deletionID != nil }, set: { if !$0 { deletionID = nil } }
        ), titleVisibility: .visible) {
            Button("Eliminar definitivamente", role: .destructive) {
                if let id = deletionID { store.deletePlan(id) }
                deletionID = nil
            }
            Button("Cancelar", role: .cancel) { deletionID = nil }
        } message: { Text("Esta acción elimina el plan y no se puede deshacer.") }
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
