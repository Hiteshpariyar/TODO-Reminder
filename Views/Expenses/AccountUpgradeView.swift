// AccountUpgradeView.swift
// Screen presenting guest status, explanation of online sync benefits, and account upgrade/migration

import SwiftUI
import SwiftData

public struct AccountUpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject var guestService: GuestIdentityService
    @EnvironmentObject var viewModel: ExpenseGroupsViewModel

    @State private var emailInput: String = ""
    @State private var migrationMessage: String?
    @State private var isMigrating: Bool = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundDark.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header Glass Card
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: guestService.isGuest ? "person.crop.circle.badge.checkmark" : "person.crop.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(Color.primaryStart)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(guestService.isGuest ? "Guest Mode Active" : "Registered Account")
                                        .font(.title3.bold().rounded())
                                        .foregroundColor(.white)
                                    Text(guestService.isGuest ? "Local Device Profile" : (guestService.authenticatedEmail ?? ""))
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                Spacer()
                            }

                            Divider().background(Color.white.opacity(0.2))

                            Text("Device Installation ID:")
                                .font(.caption2.bold())
                                .foregroundColor(.white.opacity(0.5))
                            Text(guestService.installationId)
                                .font(.system(size: 11, weight: .regular, design: .monospaced))
                                .foregroundColor(.white.opacity(0.75))
                        }
                        .padding()
                        .background(.ultraThinMaterial.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.2), lineWidth: 0.5))

                        // Features Comparison
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Mode Capabilities")
                                .font(.headline)
                                .foregroundColor(.white)

                            CapabilityRow(title: "Offline Groups & Calculations", isAvailable: true, description: "Create groups, split bills, and compute net balances offline.")
                            CapabilityRow(title: "Unregistered Members", isAvailable: true, description: "Add friends by name without asking for phone numbers or emails.")
                            CapabilityRow(title: "Cloud Backup & Multi-Device Sync", isAvailable: !guestService.isGuest, description: "Access your expense groups on any phone, tablet, or web browser.")
                            CapabilityRow(title: "Group Invite Links", isAvailable: !guestService.isGuest, description: "Share a live link so friends can add expenses together in real time.")
                        }
                        .padding()
                        .background(.ultraThinMaterial.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 20))

                        if guestService.isGuest {
                            // Upgrade / Sign in Form
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Upgrade to Account")
                                    .font(.headline)
                                    .foregroundColor(.white)

                                Text("Sign in or register to back up your groups. Your local guest expenses will be seamlessly transferred to your new account.")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))

                                TextField("Enter your email", text: $emailInput)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .padding()
                                    .background(.ultraThinMaterial.opacity(0.2))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .foregroundColor(.white)
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.25), lineWidth: 0.5))

                                Button(action: upgradeAccount) {
                                    HStack {
                                        if isMigrating {
                                            ProgressView()
                                                .tint(.white)
                                                .padding(.trailing, 6)
                                        }
                                        Text("Link Account & Migrate Data")
                                            .font(.headline)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        AngularGradient(colors: [Color.primaryStart, Color.primaryEnd], center: .center)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                                .disabled(emailInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isMigrating)
                                .opacity(emailInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
                            }
                            .padding()
                            .background(.ultraThinMaterial.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        } else {
                            // Logout button
                            VStack(spacing: 12) {
                                Button(action: logoutAccount) {
                                    Text("Sign Out to Guest Mode")
                                        .font(.headline)
                                        .foregroundColor(.red.opacity(0.9))
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.red.opacity(0.15))
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.red.opacity(0.4), lineWidth: 0.6))
                                }
                                Text("Signing out will NOT delete your local groups or data.")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .padding()
                        }

                        if let msg = migrationMessage {
                            Text(msg)
                                .font(.subheadline.bold())
                                .foregroundColor(.green)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.green.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Account & Storage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }

    private func upgradeAccount() {
        let clean = emailInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }

        isMigrating = true
        let newUserId = "user_" + UUID().uuidString
        guestService.simulateLogin(userId: newUserId, email: clean)

        do {
            let result = try GuestMigrationService.shared.migrateGuestDataToAccount(
                authenticatedUserId: newUserId,
                context: context,
                groups: viewModel.groups
            )
            migrationMessage = "Success! Migrated \(result.groupsMigrated) groups and \(result.expensesMigrated) expenses."
            viewModel.loadGroups()
        } catch {
            migrationMessage = "Migration note: \(error.localizedDescription)"
        }
        isMigrating = false
    }

    private func logoutAccount() {
        guestService.logout()
        dismiss()
    }
}

struct CapabilityRow: View {
    let title: String
    let isAvailable: Bool
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: isAvailable ? "checkmark.circle.fill" : "lock.circle")
                .foregroundColor(isAvailable ? .green : .orange.opacity(0.8))
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.65))
            }
        }
    }
}
