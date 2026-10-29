// GuestMigrationService.swift
// Handles safe, idempotent migration from local guest profiles into authenticated accounts.

import Foundation
import SwiftData

public struct MigrationResult {
    public let groupsMigrated: Int
    public let membersMigrated: Int
    public let expensesMigrated: Int
    public let settlementsMigrated: Int
    public let errors: [String]
}

public protocol GuestMigrationServiceProtocol {
    func migrateGuestDataToAccount(
        authenticatedUserId: String,
        context: ModelContext,
        groups: [ExpenseGroup]
    ) throws -> MigrationResult
}

public final class GuestMigrationService: GuestMigrationServiceProtocol {
    public static let shared = GuestMigrationService()
    public init() {}

    /// Migrates guest data to an authenticated user account.
    /// Retrying this operation is safe and idempotent.
    public func migrateGuestDataToAccount(
        authenticatedUserId: String,
        context: ModelContext,
        groups: [ExpenseGroup]
    ) throws -> MigrationResult {
        var groupsCount = 0
        var membersCount = 0
        var expensesCount = 0
        var settlementsCount = 0
        var errors: [String] = []

        let guestInstallationId = GuestIdentityService.shared.installationId

        for group in groups {
            // Only migrate groups owned by the current guest installation
            if group.ownerInstallationId == guestInstallationId || group.isLocalOnly {
                group.ownerInstallationId = authenticatedUserId
                group.isLocalOnly = false
                group.syncStatus = .pendingCreation
                group.updatedAt = Date()
                groupsCount += 1

                // Associate current user member record with the new account
                for member in group.members {
                    if member.isCurrentUser {
                        member.isGuestLocal = false
                        member.externalUserId = authenticatedUserId
                        membersCount += 1
                    }
                    // Crucial: other members remain distinct entities with stable UUIDs;
                    // never merge members solely by display name!
                }

                for expense in group.expenses {
                    expense.syncStatus = .pendingCreation
                    expense.updatedAt = Date()
                    expensesCount += 1
                }

                for settlement in group.settlements {
                    settlement.syncStatus = .pendingCreation
                    settlementsCount += 1
                }
            }
        }

        do {
            try context.save()
        } catch {
            errors.append("Failed to commit migration transaction: \(error.localizedDescription)")
            throw error
        }

        return MigrationResult(
            groupsMigrated: groupsCount,
            membersMigrated: membersCount,
            expensesMigrated: expensesCount,
            settlementsMigrated: settlementsCount,
            errors: errors
        )
    }
}
