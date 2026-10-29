// AddExpenseView.swift
// Screen for recording a new expense with minor-unit accuracy and split type selection

import SwiftUI

public struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: ExpenseGroupsViewModel

    public let group: ExpenseGroup

    @State private var title: String = ""
    @State private var amountString: String = ""
    @State private var category: String = "General"
    @State private var selectedPayerId: UUID
    @State private var selectedSplitType: SplitType = .equal
    @State private var selectedMemberIds: Set<UUID> = []

    let categories = ["General", "Food & Dining", "Groceries", "Transport", "Entertainment", "Lodging"]

    public init(group: ExpenseGroup) {
        self.group = group
        let initialPayer = group.members.first(where: { $0.isCurrentUser })?.id ?? group.members.first?.id ?? UUID()
        _selectedPayerId = State(initialValue: initialPayer)
        _selectedMemberIds = State(initialValue: Set(group.members.map { $0.id }))
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundDark.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Title and Amount Section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Expense Details")
                                .font(.headline)
                                .foregroundColor(.white)

                            TextField("Title (e.g., Team Lunch)", text: $title)
                                .padding()
                                .background(.ultraThinMaterial.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .foregroundColor(.white)
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.25), lineWidth: 0.5))

                            HStack {
                                Text(group.currencyCode)
                                    .font(.title2.bold())
                                    .foregroundColor(Color.accentStart)
                                TextField("0.00", text: $amountString)
                                    .keyboardType(.decimalPad)
                                    .font(.title2.bold().monospacedDigit())
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .background(.ultraThinMaterial.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.25), lineWidth: 0.5))

                            Picker("Category", selection: $category) {
                                ForEach(categories, id: \.self) { cat in
                                    Text(cat).tag(cat)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(.top, 4)
                        }
                        .padding()
                        .background(.ultraThinMaterial.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 20))

                        // Paid By Section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Paid By")
                                .font(.headline)
                                .foregroundColor(.white)

                            Picker("Payer", selection: $selectedPayerId) {
                                ForEach(group.members) { member in
                                    Text(member.name + (member.isCurrentUser ? " (You)" : "")).tag(member.id)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 110)
                        }
                        .padding()
                        .background(.ultraThinMaterial.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 20))

                        // Split Method Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Split Type")
                                .font(.headline)
                                .foregroundColor(.white)

                            Picker("Split Type", selection: $selectedSplitType) {
                                Text("Equally").tag(SplitType.equal)
                                Text("Percentages").tag(SplitType.percentage)
                                Text("Shares").tag(SplitType.shares)
                            }
                            .pickerStyle(.segmented)

                            Text("Split With")
                                .font(.subheadline.bold())
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.top, 4)

                            ForEach(group.members) { member in
                                HStack {
                                    Image(systemName: selectedMemberIds.contains(member.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedMemberIds.contains(member.id) ? Color.primaryStart : .white.opacity(0.4))
                                    Text(member.name + (member.isCurrentUser ? " (You)" : ""))
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if selectedMemberIds.contains(member.id) {
                                        if selectedMemberIds.count > 1 {
                                            selectedMemberIds.remove(member.id)
                                        }
                                    } else {
                                        selectedMemberIds.insert(member.id)
                                    }
                                }
                                .padding(.vertical, 6)
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 20))

                        // Save Button
                        Button(action: saveExpense) {
                            Text("Save Expense")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    AngularGradient(colors: [Color.primaryStart, Color.primaryEnd], center: .center)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                                .shadow(color: Color.primaryStart.opacity(0.4), radius: 10, y: 5)
                        }
                        .padding(.top, 10)
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }

    private func parseMinorUnits(from text: String) -> Int64? {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
        guard let decimal = Decimal(string: clean), decimal > 0 else { return nil }
        let multiplied = decimal * 100
        let doubleVal = NSDecimalNumber(decimal: multiplied).doubleValue
        return Int64(round(doubleVal))
    }

    private func saveExpense() {
        guard let minorUnits = parseMinorUnits(from: amountString) else { return }

        let success = viewModel.addExpense(
            to: group,
            title: title,
            amountMinorUnits: minorUnits,
            category: category,
            payerId: selectedPayerId,
            splitType: selectedSplitType,
            selectedMemberIds: Array(selectedMemberIds)
        )

        if success {
            dismiss()
        }
    }
}
