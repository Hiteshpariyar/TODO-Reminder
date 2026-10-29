// ExpenseCalculationEngine.swift
// Authoritative calculation engine for Splid-inspired offline-first expense splitting
// Strictly uses Int64 minor currency units (e.g., cents, pence) to avoid floating-point errors.

import Foundation

public struct ProposedSettlement: Identifiable, Hashable {
    public var id: UUID = UUID()
    public var fromMemberId: UUID
    public var toMemberId: UUID
    public var amountMinorUnits: Int64

    public init(id: UUID = UUID(), fromMemberId: UUID, toMemberId: UUID, amountMinorUnits: Int64) {
        self.id = id
        self.fromMemberId = fromMemberId
        self.toMemberId = toMemberId
        self.amountMinorUnits = amountMinorUnits
    }
}

public enum CalculationError: Error, LocalizedError {
    case emptyMembers
    case invalidTotal
    case splitMismatch(expected: Int64, actual: Int64)
    case invalidPercentageSum(actual: Double)
    case nonPositiveShares

    public var errorDescription: String? {
        switch self {
        case .emptyMembers:
            return "At least one member is required to split an expense."
        case .invalidTotal:
            return "Expense total must be greater than zero."
        case .splitMismatch(let expected, let actual):
            return "Split allocations (\(actual)) do not equal the total amount (\(expected))."
        case .invalidPercentageSum(let actual):
            return "Split percentages must sum to 100.0% (got \(actual)%)."
        case .nonPositiveShares:
            return "Shares must be positive numbers."
        }
    }
}

public final class ExpenseCalculationEngine {
    public static let shared = ExpenseCalculationEngine()
    public init() {}

    // MARK: - Split Distribution Algorithms

    /// Distributes total minor units equally among member IDs.
    /// Distributes any integer remainder cents deterministically across the members sorted by ID.
    public func distributeEqualSplit(
        totalMinorUnits: Int64,
        memberIds: [UUID]
    ) throws -> [UUID: Int64] {
        guard !memberIds.isEmpty else { throw CalculationError.emptyMembers }
        guard totalMinorUnits >= 0 else { throw CalculationError.invalidTotal }
        if totalMinorUnits == 0 {
            return Dictionary(uniqueKeysWithValues: memberIds.map { ($0, Int64(0)) })
        }

        let sortedMembers = memberIds.sorted(by: { $0.uuidString < $1.uuidString })
        let count = Int64(sortedMembers.count)
        let baseShare = totalMinorUnits / count
        let remainder = totalMinorUnits % count

        var result: [UUID: Int64] = [:]
        for (index, memberId) in sortedMembers.enumerated() {
            // First 'remainder' members receive +1 minor unit
            let extra = Int64(index) < remainder ? Int64(1) : Int64(0)
            result[memberId] = baseShare + extra
        }
        return result
    }

    /// Distributes total minor units proportionally by percentage (0 - 100).
    /// Enforces percentage sum of ~100.0, rounds deterministically, and allocates remainder minor units.
    public func distributePercentageSplit(
        totalMinorUnits: Int64,
        percentages: [UUID: Double]
    ) throws -> [UUID: Int64] {
        guard !percentages.isEmpty else { throw CalculationError.emptyMembers }
        guard totalMinorUnits >= 0 else { throw CalculationError.invalidTotal }

        let totalPercentage = percentages.values.reduce(0.0, +)
        if abs(totalPercentage - 100.0) > 0.01 {
            throw CalculationError.invalidPercentageSum(actual: totalPercentage)
        }

        let sortedKeys = percentages.keys.sorted(by: { $0.uuidString < $1.uuidString })
        var result: [UUID: Int64] = [:]
        var allocatedSum: Int64 = 0

        // Track fractional parts for largest-remainder method
        var fractions: [(id: UUID, fraction: Double)] = []

        for memberId in sortedKeys {
            let percent = percentages[memberId] ?? 0.0
            let exact = Double(totalMinorUnits) * (percent / 100.0)
            let floorUnits = Int64(floor(exact))
            result[memberId] = floorUnits
            allocatedSum += floorUnits
            fractions.append((id: memberId, fraction: exact - Double(floorUnits)))
        }

        // Distribute remainder units to members with largest fractional parts
        var remainder = totalMinorUnits - allocatedSum
        fractions.sort(by: {
            if abs($0.fraction - $1.fraction) > 0.000001 {
                return $0.fraction > $1.fraction
            }
            return $0.id.uuidString < $1.id.uuidString
        })

        var idx = 0
        while remainder > 0 && idx < fractions.count {
            let memberId = fractions[idx].id
            result[memberId] = (result[memberId] ?? 0) + 1
            remainder -= 1
            idx += 1
        }

        return result
    }

    /// Distributes total minor units proportionally by share counts (e.g. 1 share, 2 shares, 0.5 shares).
    public func distributeShareSplit(
        totalMinorUnits: Int64,
        shares: [UUID: Double]
    ) throws -> [UUID: Int64] {
        guard !shares.isEmpty else { throw CalculationError.emptyMembers }
        guard totalMinorUnits >= 0 else { throw CalculationError.invalidTotal }

        let totalShares = shares.values.reduce(0.0, +)
        guard totalShares > 0 else { throw CalculationError.nonPositiveShares }

        let sortedKeys = shares.keys.sorted(by: { $0.uuidString < $1.uuidString })
        var result: [UUID: Int64] = [:]
        var allocatedSum: Int64 = 0
        var fractions: [(id: UUID, fraction: Double)] = []

        for memberId in sortedKeys {
            let share = shares[memberId] ?? 0.0
            let exact = Double(totalMinorUnits) * (share / totalShares)
            let floorUnits = Int64(floor(exact))
            result[memberId] = floorUnits
            allocatedSum += floorUnits
            fractions.append((id: memberId, fraction: exact - Double(floorUnits)))
        }

        var remainder = totalMinorUnits - allocatedSum
        fractions.sort(by: {
            if abs($0.fraction - $1.fraction) > 0.000001 {
                return $0.fraction > $1.fraction
            }
            return $0.id.uuidString < $1.id.uuidString
        })

        var idx = 0
        while remainder > 0 && idx < fractions.count {
            let memberId = fractions[idx].id
            result[memberId] = (result[memberId] ?? 0) + 1
            remainder -= 1
            idx += 1
        }

        return result
    }

    // MARK: - Balance Calculation Engine

    /// Calculates net balance for every member in the group.
    /// Net Balance = Total Paid - Total Owed.
    /// Positive = Creditor (owed money by the group).
    /// Negative = Debtor (owes money to the group).
    /// Mathematical Invariant: sum of all net balances is strictly 0.
    public func calculateNetBalances(
        memberIds: [UUID],
        expenses: [Expense],
        settlements: [Settlement]
    ) -> [UUID: Int64] {
        var balances: [UUID: Int64] = Dictionary(uniqueKeysWithValues: memberIds.map { ($0, Int64(0)) })

        // Process expenses
        for expense in expenses {
            // Add what each payer paid
            for payer in expense.payers {
                balances[payer.memberId, default: 0] += payer.amountMinorUnits
            }
            // Subtract what each split participant owes
            for split in expense.splits {
                balances[split.memberId, default: 0] -= split.allocatedMinorUnits
            }
        }

        // Process settlements
        for settlement in settlements {
            // Payer paid money -> balance increases (+), receiver received money -> balance decreases (-)
            balances[settlement.payerMemberId, default: 0] += settlement.amountMinorUnits
            balances[settlement.receiverMemberId, default: 0] -= settlement.amountMinorUnits
        }

        return balances
    }

    // MARK: - Debt Simplification (Min-Cash-Flow Algorithm)

    /// Computes the minimal number of direct settlements required to resolve all debts.
    /// Applies a deterministic greedy min-cash-flow pairing algorithm.
    public func calculateSimplifiedSettlements(
        netBalances: [UUID: Int64]
    ) -> [ProposedSettlement] {
        // Separate creditors and debtors
        var debtors: [(id: UUID, amount: Int64)] = []
        var creditors: [(id: UUID, amount: Int64)] = []

        for (memberId, balance) in netBalances {
            if balance < 0 {
                debtors.append((id: memberId, amount: -balance)) // positive debt amount
            } else if balance > 0 {
                creditors.append((id: memberId, amount: balance))
            }
        }

        // Deterministic sorting: largest amounts first, ties broken by UUID
        debtors.sort(by: { $0.amount > $1.amount || ($0.amount == $1.amount && $0.id.uuidString < $1.id.uuidString) })
        creditors.sort(by: { $0.amount > $1.amount || ($0.amount == $1.amount && $0.id.uuidString < $1.id.uuidString) })

        var proposed: [ProposedSettlement] = []

        var debtorIndex = 0
        var creditorIndex = 0

        while debtorIndex < debtors.count && creditorIndex < creditors.count {
            let debtor = debtors[debtorIndex]
            let creditor = creditors[creditorIndex]

            let settleAmount = min(debtor.amount, creditor.amount)

            if settleAmount > 0 {
                proposed.append(ProposedSettlement(
                    fromMemberId: debtor.id,
                    toMemberId: creditor.id,
                    amountMinorUnits: settleAmount
                ))
            }

            debtors[debtorIndex].amount -= settleAmount
            creditors[creditorIndex].amount -= settleAmount

            if debtors[debtorIndex].amount == 0 {
                debtorIndex += 1
            }
            if creditors[creditorIndex].amount == 0 {
                creditorIndex += 1
            }
        }

        return proposed
    }

    // MARK: - Currency Formatting Helper

    /// Formats an Int64 minor unit into a human-readable currency string (e.g. 1050 -> "$10.50")
    public func formatAmount(_ minorUnits: Int64, currencyCode: String = "USD") -> String {
        let isNegative = minorUnits < 0
        let absoluteUnits = abs(minorUnits)
        let major = absoluteUnits / 100
        let minor = absoluteUnits % 100
        let formatted = String(format: "%d.%02d", major, minor)

        let symbol: String
        switch currencyCode.uppercased() {
        case "USD": symbol = "$"
        case "EUR": symbol = "€"
        case "GBP": symbol = "£"
        case "INR": symbol = "₹"
        case "CAD": symbol = "CA$"
        default: symbol = "\(currencyCode) "
        }

        return isNegative ? "-\(symbol)\(formatted)" : "\(symbol)\(formatted)"
    }
}
