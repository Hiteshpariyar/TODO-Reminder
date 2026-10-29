// ExpenseComponents.swift
// Reusable Liquid Glass UI components for the Splid-inspired expense sharing module

import SwiftUI

// MARK: - Sync Status Badge
public struct SyncStatusBadge: View {
    public let state: SyncNetworkState
    public var isLocalOnly: Bool = true

    public init(state: SyncNetworkState, isLocalOnly: Bool = true) {
        self.state = state
        self.isLocalOnly = isLocalOnly
    }

    public var body: some View {
        HStack(spacing: 5) {
            Image(systemName: iconName)
                .font(.system(size: 10, weight: .bold))
            Text(isLocalOnly ? "Local Only" : state.rawValue)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(badgeBackground)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(badgeBorderColor, lineWidth: 0.6)
        )
    }

    private var iconName: String {
        if isLocalOnly { return "internaldrive" }
        switch state {
        case .localOnly: return "internaldrive"
        case .synced: return "checkmark.icloud.fill"
        case .pendingSync: return "arrow.triangle.2.circlepath.icloud"
        case .syncing: return "arrow.clockwise"
        case .offline: return "wifi.slash"
        case .syncError: return "exclamationmark.triangle.fill"
        }
    }

    private var badgeBackground: some View {
        if isLocalOnly {
            return Color.blue.opacity(0.18)
        }
        switch state {
        case .synced:
            return Color.green.opacity(0.2)
        case .pendingSync, .syncing:
            return Color.orange.opacity(0.2)
        case .offline, .syncError:
            return Color.red.opacity(0.2)
        case .localOnly:
            return Color.blue.opacity(0.18)
        }
    }

    private var badgeBorderColor: Color {
        if isLocalOnly { return Color.blue.opacity(0.4) }
        switch state {
        case .synced: return Color.green.opacity(0.5)
        case .pendingSync, .syncing: return Color.orange.opacity(0.5)
        case .offline, .syncError: return Color.red.opacity(0.5)
        case .localOnly: return Color.blue.opacity(0.4)
        }
    }
}

// MARK: - Group Card View
public struct GroupCardView: View {
    public let group: ExpenseGroup
    public let currencyFormatter: ExpenseCalculationEngine = .shared

    public init(group: ExpenseGroup) {
        self.group = group
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name)
                        .font(.title3.bold().rounded())
                        .foregroundColor(.white)
                    if !group.groupDescription.isEmpty {
                        Text(group.groupDescription)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                }
                Spacer()
                SyncStatusBadge(state: group.syncStatus == .synced ? .synced : .pendingSync, isLocalOnly: group.isLocalOnly)
            }

            Divider()
                .background(Color.white.opacity(0.2))

            HStack {
                Label("\(group.members.count) members", systemImage: "person.2.fill")
                    .font(.caption.bold())
                    .foregroundColor(.white.opacity(0.75))

                Spacer()

                let totalMinor = group.expenses.reduce(Int64(0)) { $0 + $1.totalMinorUnits }
                Text("Total: \(currencyFormatter.formatAmount(totalMinor, currencyCode: group.currencyCode))")
                    .font(.caption.bold().monospacedDigit())
                    .foregroundColor(.white)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.15))
                .background(
                    LinearGradient(
                        colors: [Color.primaryStart.opacity(0.15), Color.primaryEnd.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.25), lineWidth: 0.6)
                )
                .shadow(color: .black.opacity(0.25), radius: 15, y: 8)
        )
    }
}
