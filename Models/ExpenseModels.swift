// ExpenseModels.swift
// SwiftData models for Splid-inspired offline-first expense sharing

import Foundation
import SwiftData

public enum SyncStatus: String, Codable {
    case synced = "synced"
    case pendingCreation = "pendingCreation"
    case pendingUpdate = "pendingUpdate"
    case pendingDeletion = "pendingDeletion"
}

public enum SplitType: String, Codable, CaseIterable {
    case equal = "equal"
    case exact = "exact"
    case percentage = "percentage"
    case shares = "shares"
}

@Model
public final class ExpenseGroup {
    @Attribute(.unique) public var id: UUID = UUID()
    public var name: String
    public var groupDescription: String
    public var currencyCode: String
    public var createdAt: Date
    public var updatedAt: Date
    public var isLocalOnly: Bool
    public var syncStatusRaw: String
    public var lastSyncedAt: Date?
    public var syncVersion: Int
    public var ownerInstallationId: String

    @Relationship(deleteRule: .cascade) public var members: [GroupMember] = []
    @Relationship(deleteRule: .cascade) public var expenses: [Expense] = []
    @Relationship(deleteRule: .cascade) public var settlements: [Settlement] = []

    public var syncStatus: SyncStatus {
        get { SyncStatus(rawValue: syncStatusRaw) ?? .pendingCreation }
        set { syncStatusRaw = newValue.rawValue }
    }

    public init(
        id: UUID = UUID(),
        name: String,
        groupDescription: String = "",
        currencyCode: String = "USD",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isLocalOnly: Bool = true,
        syncStatus: SyncStatus = .pendingCreation,
        lastSyncedAt: Date? = nil,
        syncVersion: Int = 1,
        ownerInstallationId: String = ""
    ) {
        self.id = id
        self.name = name
        self.groupDescription = groupDescription
        self.currencyCode = currencyCode
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isLocalOnly = isLocalOnly
        self.syncStatusRaw = syncStatus.rawValue
        self.lastSyncedAt = lastSyncedAt
        self.syncVersion = syncVersion
        self.ownerInstallationId = ownerInstallationId
    }
}

@Model
public final class GroupMember {
    @Attribute(.unique) public var id: UUID = UUID()
    public var name: String
    public var email: String?
    public var isCurrentUser: Bool
    public var isGuestLocal: Bool
    public var externalUserId: String?
    public var createdAt: Date
    public var groupId: UUID?

    public init(
        id: UUID = UUID(),
        name: String,
        email: String? = nil,
        isCurrentUser: Bool = false,
        isGuestLocal: Bool = true,
        externalUserId: String? = nil,
        createdAt: Date = Date(),
        groupId: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.isCurrentUser = isCurrentUser
        self.isGuestLocal = isGuestLocal
        self.externalUserId = externalUserId
        self.createdAt = createdAt
        self.groupId = groupId
    }
}

public struct ExpensePayer: Codable, Identifiable, Hashable {
    public var id: UUID
    public var memberId: UUID
    public var amountMinorUnits: Int64

    public init(id: UUID = UUID(), memberId: UUID, amountMinorUnits: Int64) {
        self.id = id
        self.memberId = memberId
        self.amountMinorUnits = amountMinorUnits
    }
}

public struct ExpenseSplit: Codable, Identifiable, Hashable {
    public var id: UUID
    public var memberId: UUID
    public var allocatedMinorUnits: Int64
    public var splitTypeRaw: String
    public var splitValue: Double

    public var splitType: SplitType {
        get { SplitType(rawValue: splitTypeRaw) ?? .equal }
        set { splitTypeRaw = newValue.rawValue }
    }

    public init(
        id: UUID = UUID(),
        memberId: UUID,
        allocatedMinorUnits: Int64,
        splitType: SplitType = .equal,
        splitValue: Double = 1.0
    ) {
        self.id = id
        self.memberId = memberId
        self.allocatedMinorUnits = allocatedMinorUnits
        self.splitTypeRaw = splitType.rawValue
        self.splitValue = splitValue
    }
}

@Model
public final class Expense {
    @Attribute(.unique) public var id: UUID = UUID()
    public var title: String
    public var totalMinorUnits: Int64
    public var currencyCode: String
    public var date: Date
    public var notes: String?
    public var category: String
    public var groupId: UUID?
    
    // JSON-encoded persistence for complex embedded collections across SwiftData versions
    public var payersData: Data?
    public var splitsData: Data?
    
    public var createdAt: Date
    public var updatedAt: Date
    public var syncStatusRaw: String
    public var syncVersion: Int

    public var syncStatus: SyncStatus {
        get { SyncStatus(rawValue: syncStatusRaw) ?? .pendingCreation }
        set { syncStatusRaw = newValue.rawValue }
    }

    public var payers: [ExpensePayer] {
        get {
            guard let data = payersData else { return [] }
            return (try? JSONDecoder().decode([ExpensePayer].self, from: data)) ?? []
        }
        set {
            payersData = try? JSONEncoder().encode(newValue)
        }
    }

    public var splits: [ExpenseSplit] {
        get {
            guard let data = splitsData else { return [] }
            return (try? JSONDecoder().decode([ExpenseSplit].self, from: data)) ?? []
        }
        set {
            splitsData = try? JSONEncoder().encode(newValue)
        }
    }

    public init(
        id: UUID = UUID(),
        title: String,
        totalMinorUnits: Int64,
        currencyCode: String = "USD",
        date: Date = Date(),
        notes: String? = nil,
        category: String = "General",
        groupId: UUID? = nil,
        payers: [ExpensePayer] = [],
        splits: [ExpenseSplit] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        syncStatus: SyncStatus = .pendingCreation,
        syncVersion: Int = 1
    ) {
        self.id = id
        self.title = title
        self.totalMinorUnits = totalMinorUnits
        self.currencyCode = currencyCode
        self.date = date
        self.notes = notes
        self.category = category
        self.groupId = groupId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncStatusRaw = syncStatus.rawValue
        self.syncVersion = syncVersion
        self.payersData = try? JSONEncoder().encode(payers)
        self.splitsData = try? JSONEncoder().encode(splits)
    }
}

@Model
public final class Settlement {
    @Attribute(.unique) public var id: UUID = UUID()
    public var groupId: UUID?
    public var payerMemberId: UUID
    public var receiverMemberId: UUID
    public var amountMinorUnits: Int64
    public var date: Date
    public var notes: String?
    public var syncStatusRaw: String
    public var createdAt: Date

    public var syncStatus: SyncStatus {
        get { SyncStatus(rawValue: syncStatusRaw) ?? .pendingCreation }
        set { syncStatusRaw = newValue.rawValue }
    }

    public init(
        id: UUID = UUID(),
        groupId: UUID? = nil,
        payerMemberId: UUID,
        receiverMemberId: UUID,
        amountMinorUnits: Int64,
        date: Date = Date(),
        notes: String? = nil,
        syncStatus: SyncStatus = .pendingCreation,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.groupId = groupId
        self.payerMemberId = payerMemberId
        self.receiverMemberId = receiverMemberId
        self.amountMinorUnits = amountMinorUnits
        self.date = date
        self.notes = notes
        self.syncStatusRaw = syncStatus.rawValue
        self.createdAt = createdAt
    }
}
