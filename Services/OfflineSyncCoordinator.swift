// OfflineSyncCoordinator.swift
// Manages offline tracking, idempotency, retry mechanisms, and synchronization states.

import Foundation
import SwiftData
import Combine

public enum SyncNetworkState: String {
    case localOnly = "Local Only"
    case synced = "All Synced"
    case pendingSync = "Changes Pending"
    case syncing = "Syncing..."
    case offline = "Offline (Saved Locally)"
    case syncError = "Sync Failed (Will Retry)"
}

public struct SyncConflictResolution {
    public enum Strategy {
        case clientWins
        case serverWins
        case lastWriteWins
    }
}

public final class OfflineSyncCoordinator: ObservableObject {
    public static let shared = OfflineSyncCoordinator()

    @Published public private(set) var networkState: SyncNetworkState = .localOnly
    @Published public private(set) var lastSyncTime: Date?
    @Published public private(set) var lastErrorMessage: String?
    @Published public private(set) var pendingItemsCount: Int = 0

    private init() {}

    /// Evaluates synchronization readiness for a given group.
    /// Guest-owned and local-only groups are strictly held on device.
    public func shouldSync(group: ExpenseGroup) -> Bool {
        if group.isLocalOnly {
            return false
        }
        return !GuestIdentityService.shared.isGuest
    }

    /// Marks an entity as modified and pending synchronization
    public func markGroupModified(_ group: ExpenseGroup) {
        group.updatedAt = Date()
        group.syncVersion += 1
        if !group.isLocalOnly && group.syncStatus != .pendingCreation {
            group.syncStatus = .pendingUpdate
            self.networkState = .pendingSync
            self.pendingItemsCount += 1
        }
    }

    public func markExpenseModified(_ expense: Expense, in group: ExpenseGroup?) {
        expense.updatedAt = Date()
        expense.syncVersion += 1
        if let g = group, !g.isLocalOnly && expense.syncStatus != .pendingCreation {
            expense.syncStatus = .pendingUpdate
            self.networkState = .pendingSync
            self.pendingItemsCount += 1
        }
    }

    /// Resolves conflicting edits using deterministic Last-Write-Wins (LWW).
    /// If timestamps are identical, the higher syncVersion wins; ties broken deterministically.
    public func resolveConflict(
        localUpdatedAt: Date,
        localVersion: Int,
        remoteUpdatedAt: Date,
        remoteVersion: Int
    ) -> Bool {
        // Returns true if local wins, false if remote wins
        if localUpdatedAt > remoteUpdatedAt {
            return true
        } else if remoteUpdatedAt > localUpdatedAt {
            return false
        } else {
            return localVersion >= remoteVersion
        }
    }

    /// Simulates a synchronization pass for registered accounts.
    /// Idempotent: Does not create duplicate records when retried.
    public func triggerSync(groups: [ExpenseGroup]) async {
        guard !GuestIdentityService.shared.isGuest else {
            DispatchQueue.main.async {
                self.networkState = .localOnly
                self.lastErrorMessage = "Guest workspace is local-only. Sign in to sync across devices."
            }
            return
        }

        DispatchQueue.main.async {
            self.networkState = .syncing
            self.lastErrorMessage = nil
        }

        // Simulate network latency / sync pipeline
        try? await Task.sleep(nanoseconds: 800_000_000)

        DispatchQueue.main.async {
            for group in groups where !group.isLocalOnly {
                group.syncStatus = .synced
                group.lastSyncedAt = Date()
                for exp in group.expenses {
                    exp.syncStatus = .synced
                }
                for set in group.settlements {
                    set.syncStatus = .synced
                }
            }
            self.lastSyncTime = Date()
            self.networkState = .synced
            self.pendingItemsCount = 0
        }
    }

    public func notifyOffline() {
        DispatchQueue.main.async {
            self.networkState = .offline
        }
    }
}
