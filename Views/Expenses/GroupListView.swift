// GroupListView.swift
// Main screen for expense sharing: Lists groups, guest profile banner, and group creation

import SwiftUI
import SwiftData

public struct GroupListView: View {
    @EnvironmentObject var viewModel: ExpenseGroupsViewModel
    @EnvironmentObject var guestService: GuestIdentityService
    @EnvironmentObject var syncCoordinator: OfflineSyncCoordinator

    @State private var showingCreateGroup = false
    @State private var showingAccountUpgrade = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundDark.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Guest status header
                    guestBanner
                        .padding(.horizontal)
                        .padding(.top, 8)

                    if viewModel.groups.isEmpty {
                        emptyState
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 14) {
                                ForEach(viewModel.groups) { group in
                                    NavigationLink(destination: GroupDetailView(group: group)) {
                                        GroupCardView(group: group)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Expenses")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingCreateGroup = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { showingAccountUpgrade = true }) {
                        Image(systemName: guestService.isGuest ? "person.crop.circle.badge.questionmark" : "person.crop.circle.fill")
                            .foregroundColor(.white.opacity(0.85))
                    }
                }
            }
            .sheet(isPresented: $showingCreateGroup) {
                CreateGroupView()
            }
            .sheet(isPresented: $showingAccountUpgrade) {
                AccountUpgradeView()
            }
        }
    }

    private var guestBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(guestService.isGuest ? "Guest Mode" : "Account: \(guestService.authenticatedEmail ?? "")")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                    SyncStatusBadge(state: syncCoordinator.networkState, isLocalOnly: guestService.isGuest)
                }
                Text(guestService.isGuest ? "Stored locally on this device • No account required" : "Cloud synchronization active")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.65))
            }
            Spacer()
            if guestService.isGuest {
                Button("Upgrade") {
                    showingAccountUpgrade = true
                }
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.15))
                .foregroundColor(.white)
                .clipShape(Capsule())
            }
        }
        .padding(12)
        .background(.ultraThinMaterial.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
        )
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "person.3.sequence.fill")
                .font(.system(size: 64))
                .foregroundColor(.white.opacity(0.3))
            Text("No Expense Groups Yet")
                .font(.title2.bold().rounded())
                .foregroundColor(.white)
            Text("Create a group to start splitting bills and calculating balances with friends offline.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button(action: { showingCreateGroup = true }) {
                Text("Create First Group")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        AngularGradient(colors: [Color.primaryStart, Color.primaryEnd], center: .center)
                    )
                    .clipShape(Capsule())
                    .shadow(color: Color.primaryStart.opacity(0.4), radius: 10, y: 4)
            }
            .padding(.top, 8)
            Spacer()
        }
    }
}
