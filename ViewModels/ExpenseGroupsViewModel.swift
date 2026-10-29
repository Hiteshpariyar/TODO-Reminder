// ExpenseGroupsViewModel.swift
// ViewModel managing Groups, Members, Expenses, and Settlements

import Foundation
import SwiftData
import SwiftUI
import Combine

@MainActor
public final class ExpenseGroupsViewModel: ObservableObject {
    @Published public var groups: [ExpenseGroup] = []
    @Published public var selectedGroup: ExpenseGroup?
    @Published public var errorMessage: String?

    private var modelContext: ModelContext?
    private let engine = ExpenseCalculationEngine.shared
    private let syncCoordinator = OfflineSyncCoordinator.shared
    private let guestService = GuestIdentityService.shared

    public init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }

    public func setContext(_ context: ModelContext) {
        self.modelContext = context
        loadGroups()
    }

    public func loadGroups() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<ExpenseGroup>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        do {
            self.groups = try context.fetch(descriptor)
        } catch {
            self.errorMessage = "Failed to load groups: \(error.localizedDescription)"
        }
    }

    // MARK: - Group Management

    public func createGroup(
        name: String,
        description: String = "",
        currencyCode: String = "USD",
        memberNames: [String] = []
    ) -> ExpenseGroup? {
        guard let context = modelContext else { return nil }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return nil }

        let group = ExpenseGroup(
            name: trimmedName,
            groupDescription: description,
            currencyCode: currencyCode,
            isLocalOnly: true,
            syncStatus: .pendingCreation,
            ownerInstallationId: guestService.installationId
        )

        // Always add current guest user as first member
        let currentGuestMember = GroupMember(
            name: guestService.guestDisplayName,
            isCurrentUser: true,
            isGuestLocal: true,
            groupId: group.id
        )
        group.members.append(currentGuestMember)

        // Add additional local members without requiring accounts
        for name in memberNames {
            let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
            if !clean.isEmpty {
                let member = GroupMember(
                    name: clean,
                    isCurrentUser: false,
                    isGuestLocal: true,
                    groupId: group.id
                )
                group.members.append(member)
            }
        }

        context.insert(group)
        do {
            try context.save()
            loadGroups()
            return group
        } catch {
            self.errorMessage = "Failed to create group: \(error.localizedDescription)"
            return nil
        }
    }

    public func deleteGroup(_ group: ExpenseGroup) {
        guard let context = modelContext else { return }
        context.delete(group)
        do {
            try context.save()
            loadGroups()
        } catch {
            self.errorMessage = "Failed to delete group: \(error.localizedDescription)"
        }
    }

    public func addMember(to group: ExpenseGroup, name: String) {
        guard let context = modelContext else { return }
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }

        let member = GroupMember(
            name: clean,
            isCurrentUser: false,
            isGuestLocal: true,
            groupId: group.id
        )
        group.members.append(member)
        syncCoordinator.markGroupModified(group)

        do {
            try context.save()
            loadGroups()
        } catch {
            self.errorMessage = "Failed to add member: \(error.localizedDescription)"
        }
    }

    // MARK: - Expense Management

    public func addExpense(
        to group: ExpenseGroup,
        title: String,
        amountMinorUnits: Int64,
        category: String,
        payerId: UUID,
        splitType: SplitType,
        selectedMemberIds: [UUID],
        customSplits: [UUID: Int64]? = nil
    ) -> Bool {
        guard let context = modelContext else { return false }
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty, amountMinorUnits > 0, !selectedMemberIds.isEmpty else {
            self.errorMessage = "Please enter valid expense details."
            return false
        }

        let payers = [ExpensePayer(memberId: payerId, amountMinorUnits: amountMinorUnits)]
        var splits: [ExpenseSplit] = []

        do {
            switch splitType {
            case .equal:
                let allocation = try engine.distributeEqualSplit(
                    totalMinorUnits: amountMinorUnits,
                    memberIds: selectedMemberIds
                )
                splits = allocation.map {
                    ExpenseSplit(memberId: $0.key, allocatedMinorUnits: $0.value, splitType: .equal)
                }

            case .exact:
                if let custom = customSplits {
                    let totalCustom = custom.values.reduce(0, +)
                    guard totalCustom == amountMinorUnits else {
                        self.errorMessage = "Exact splits sum (\(totalCustom)) does not match total (\(amountMinorUnits))."
                        return false
                    }
                    splits = custom.map {
                        ExpenseSplit(memberId: $0.key, allocatedMinorUnits: $0.value, splitType: .exact)
                    }
                } else {
                    return false
                }

            case .percentage:
                // Default equal percentages
                let pct = 100.0 / Double(selectedMemberIds.count)
                let pctMap = Dictionary(uniqueKeysWithValues: selectedMemberIds.map { ($0, pct) })
                let allocation = try engine.distributePercentageSplit(
                    totalMinorUnits: amountMinorUnits,
                    percentages: pctMap
                )
                splits = allocation.map {
                    ExpenseSplit(memberId: $0.key, allocatedMinorUnits: $0.value, splitType: .percentage, splitValue: pct)
                }

            case .shares:
                let shareMap = Dictionary(uniqueKeysWithValues: selectedMemberIds.map { ($0, 1.0) })
                let allocation = try engine.distributeShareSplit(
                    totalMinorUnits: amountMinorUnits,
                    shares: shareMap
                )
                splits = allocation.map {
                    ExpenseSplit(memberId: $0.key, allocatedMinorUnits: $0.value, splitType: .shares, splitValue: 1.0)
                }
            }
        } catch {
            self.errorMessage = error.localizedDescription
            return false
        }

        let expense = Expense(
            title: cleanTitle,
            totalMinorUnits: amountMinorUnits,
            currencyCode: group.currencyCode,
            category: category,
            groupId: group.id,
            payers: payers,
            splits: splits
        )

        group.expenses.append(expense)
        syncCoordinator.markExpenseModified(expense, in: group)

        do {
            try context.save()
            loadGroups()
            return true
        } catch {
            self.errorMessage = "Failed to save expense: \(error.localizedDescription)"
            return false
        }
    }

    public func deleteExpense(_ expense: Expense, from group: ExpenseGroup) {
        guard let context = modelContext else { return }
        if let idx = group.expenses.firstIndex(where: { $0.id == expense.id }) {
            group.expenses.remove(at: idx)
        }
        context.delete(expense)
        syncCoordinator.markGroupModified(group)
        do {
            try context.save()
            loadGroups()
        } catch {
            self.errorMessage = "Failed to delete expense: \(error.localizedDescription)"
        }
    }

    // MARK: - Settlement Management

    public func recordSettlement(
        in group: ExpenseGroup,
        from payerId: UUID,
        to receiverId: UUID,
        amountMinorUnits: Int64,
        notes: String? = nil
    ) -> Bool {
        guard let context = modelContext else { return false }
        guard amountMinorUnits > 0, payerId != receiverId else { return false }

        let settlement = Settlement(
            groupId: group.id,
            payerMemberId: payerId,
            receiverMemberId: receiverId,
            amountMinorUnits: amountMinorUnits,
            notes: notes
        )

        group.settlements.append(settlement)
        syncCoordinator.markGroupModified(group)

        do {
            try context.save()
            loadGroups()
            return true
        } catch {
            self.errorMessage = "Failed to record settlement: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Calculations

    public func getNetBalances(for group: ExpenseGroup) -> [UUID: Int64] {
        let memberIds = group.members.map { $0.id }
        return engine.calculateNetBalances(
            memberIds: memberIds,
            expenses: group.expenses,
            settlements: group.settlements
        )
    }

    public func getSimplifiedSettlements(for group: ExpenseGroup) -> [ProposedSettlement] {
        let balances = getNetBalances(for: group)
        return engine.calculateSimplifiedSettlements(netBalances: balances)
    }
}
