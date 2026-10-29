// GroupDetailView.swift
// Detailed view for an Expense Group with Expenses, Balances, and Settlements tabs

import SwiftUI

public struct GroupDetailView: View {
    public let group: ExpenseGroup

    @EnvironmentObject var viewModel: ExpenseGroupsViewModel
    @State private var selectedTab: Int = 0
    @State private var showingAddExpense: Bool = false
    @State private var showingAddMember: Bool = false

    private let engine = ExpenseCalculationEngine.shared

    public init(group: ExpenseGroup) {
        self.group = group
    }

    public var body: some View {
        ZStack {
            Color.backgroundDark.ignoresSafeArea()

            VStack(spacing: 0) {
                // Custom Tab Segmented Control
                HStack(spacing: 0) {
                    TabButton(title: "Expenses", isSelected: selectedTab == 0) { selectedTab = 0 }
                    TabButton(title: "Balances", isSelected: selectedTab == 1) { selectedTab = 1 }
                    TabButton(title: "Settlements", isSelected: selectedTab == 2) { selectedTab = 2 }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial.opacity(0.15))

                // Tab Content
                TabView(selection: $selectedTab) {
                    expensesTab.tag(0)
                    balancesTab.tag(1)
                    settlementsTab.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }

            // Floating Add Expense Button (only on Expenses tab)
            if selectedTab == 0 {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showingAddExpense = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(
                                    AngularGradient(colors: [Color.primaryStart, Color.primaryEnd], center: .center)
                                        .clipShape(Circle())
                                        .shadow(color: Color.primaryStart.opacity(0.4), radius: 15, y: 8)
                                )
                        }
                        .padding(20)
                    }
                }
            }
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingAddMember = true }) {
                    Label("Add Member", systemImage: "person.badge.plus")
                        .foregroundColor(.white)
                }
            }
        }
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseView(group: group)
        }
        .sheet(isPresented: $showingAddMember) {
            AddMemberView(group: group)
        }
    }

    // MARK: - Expenses Tab
    private var expensesTab: some View {
        ScrollView {
            if group.expenses.isEmpty {
                VStack(spacing: 12) {
                    Spacer(minLength: 60)
                    Image(systemName: "receipt")
                        .font(.system(size: 50))
                        .foregroundColor(.white.opacity(0.3))
                    Text("No Expenses Recorded")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Tap the + button to add the first expense.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(group.expenses) { expense in
                        ExpenseRowView(expense: expense, currencyCode: group.currencyCode, members: group.members) {
                            viewModel.deleteExpense(expense, from: group)
                        }
                    }
                }
                .padding()
                .padding(.bottom, 80)
            }
        }
    }

    // MARK: - Balances Tab
    private var balancesTab: some View {
        let balances = viewModel.getNetBalances(for: group)

        return ScrollView {
            VStack(spacing: 14) {
                ForEach(group.members) { member in
                    let net = balances[member.id] ?? 0
                    MemberBalanceCard(member: member, netBalance: net, currencyCode: group.currencyCode)
                }
            }
            .padding()
        }
    }

    // MARK: - Settlements Tab
    private var settlementsTab: some View {
        let proposed = viewModel.getSimplifiedSettlements(for: group)

        return ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Suggested Settlements")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal)

                if proposed.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.green.opacity(0.8))
                        Text("All Settled Up!")
                            .font(.title3.bold().rounded())
                            .foregroundColor(.white)
                        Text("No outstanding debts between members.")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(30)
                    .background(.ultraThinMaterial.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(proposed) { p in
                            let fromMember = group.members.first(where: { $0.id == p.fromMemberId })?.name ?? "Unknown"
                            let toMember = group.members.first(where: { $0.id == p.toMemberId })?.name ?? "Unknown"

                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(fromMember).bold()
                                        Image(systemName: "arrow.right")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.6))
                                        Text(toMember).bold()
                                    }
                                    .foregroundColor(.white)

                                    Text(engine.formatAmount(p.amountMinorUnits, currencyCode: group.currencyCode))
                                        .font(.title3.bold().monospacedDigit())
                                        .foregroundColor(Color.accentStart)
                                }

                                Spacer()

                                Button("Mark Paid") {
                                    _ = viewModel.recordSettlement(
                                        in: group,
                                        from: p.fromMemberId,
                                        to: p.toMemberId,
                                        amountMinorUnits: p.amountMinorUnits
                                    )
                                }
                                .font(.caption.bold())
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.green.opacity(0.25))
                                .foregroundColor(.green)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Color.green.opacity(0.6), lineWidth: 1))
                            }
                            .padding()
                            .background(.ultraThinMaterial.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                        }
                    }
                    .padding(.horizontal)
                }

                if !group.settlements.isEmpty {
                    Text("Payment History")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .padding(.top, 10)

                    LazyVStack(spacing: 10) {
                        ForEach(group.settlements) { s in
                            let from = group.members.first(where: { $0.id == s.payerMemberId })?.name ?? "Unknown"
                            let to = group.members.first(where: { $0.id == s.receiverMemberId })?.name ?? "Unknown"
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("\(from) paid \(to)")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                Spacer()
                                Text(engine.formatAmount(s.amountMinorUnits, currencyCode: group.currencyCode))
                                    .font(.subheadline.bold().monospacedDigit())
                                    .foregroundColor(.white)
                            }
                            .padding(12)
                            .background(Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Subcomponents
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                Rectangle()
                    .fill(isSelected ? Color.primaryStart : Color.clear)
                    .frame(height: 2)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct ExpenseRowView: View {
    let expense: Expense
    let currencyCode: String
    let members: [GroupMember]
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.title)
                    .font(.headline.rounded())
                    .foregroundColor(.white)

                let payerName = members.first(where: { $0.id == expense.payers.first?.memberId })?.name ?? "Unknown"
                Text("Paid by \(payerName)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(ExpenseCalculationEngine.shared.formatAmount(expense.totalMinorUnits, currencyCode: currencyCode))
                    .font(.headline.bold().monospacedDigit())
                    .foregroundColor(.white)

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red.opacity(0.8))
                }
            }
        }
        .padding(14)
        .background(.ultraThinMaterial.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.2), lineWidth: 0.5))
    }
}

struct MemberBalanceCard: View {
    let member: GroupMember
    let netBalance: Int64
    let currencyCode: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(member.name)
                        .font(.headline.rounded())
                        .foregroundColor(.white)
                    if member.isCurrentUser {
                        Text("You")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Capsule())
                            .foregroundColor(.white)
                    }
                }
                Text(member.isGuestLocal ? "Local member" : "Verified user")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if netBalance > 0 {
                    Text("gets back")
                        .font(.caption2.bold())
                        .foregroundColor(.green)
                    Text(ExpenseCalculationEngine.shared.formatAmount(netBalance, currencyCode: currencyCode))
                        .font(.title3.bold().monospacedDigit())
                        .foregroundColor(.green)
                } else if netBalance < 0 {
                    Text("owes")
                        .font(.caption2.bold())
                        .foregroundColor(.red.opacity(0.9))
                    Text(ExpenseCalculationEngine.shared.formatAmount(netBalance, currencyCode: currencyCode))
                        .font(.title3.bold().monospacedDigit())
                        .foregroundColor(.red.opacity(0.9))
                } else {
                    Text("settled up")
                        .font(.caption.bold())
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(netBalance > 0 ? Color.green.opacity(0.3) : (netBalance < 0 ? Color.red.opacity(0.3) : Color.white.opacity(0.15)), lineWidth: 0.6)
                )
        )
    }
}
