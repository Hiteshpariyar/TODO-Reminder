// CreateGroupView.swift
// Sheet to create a new group and add initial local unregistered members

import SwiftUI

public struct CreateGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: ExpenseGroupsViewModel
    @EnvironmentObject var guestService: GuestIdentityService

    @State private var groupName: String = ""
    @State private var groupDescription: String = ""
    @State private var selectedCurrency: String = "USD"
    @State private var memberNames: [String] = [""]

    let currencies = ["USD", "EUR", "GBP", "INR", "CAD"]

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundDark.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Group Details Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Group Details")
                                .font(.headline)
                                .foregroundColor(.white)

                            TextField("Group Name (e.g., Vacation Trip)", text: $groupName)
                                .padding()
                                .background(.ultraThinMaterial.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .foregroundColor(.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
                                )

                            TextField("Description (optional)", text: $groupDescription)
                                .padding()
                                .background(.ultraThinMaterial.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .foregroundColor(.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
                                )

                            Picker("Currency", selection: $selectedCurrency) {
                                ForEach(currencies, id: \.self) { curr in
                                    Text(curr).tag(curr)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.top, 6)
                        }
                        .padding()
                        .background(.ultraThinMaterial.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 20))

                        // Members Section
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Members")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                                Text("Local Only")
                                    .font(.caption.bold())
                                    .foregroundColor(.blue.opacity(0.8))
                            }

                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(Color.primaryStart)
                                Text("\(guestService.guestDisplayName) (You)")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                                Spacer()
                                Text("Owner")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.white.opacity(0.15))
                                    .clipShape(Capsule())
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(12)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                            ForEach(memberNames.indices, id: \.self) { index in
                                HStack {
                                    Image(systemName: "person")
                                        .foregroundColor(.white.opacity(0.6))
                                    TextField("Member name", text: $memberNames[index])
                                        .foregroundColor(.white)
                                    if memberNames.count > 1 {
                                        Button(action: { memberNames.remove(at: index) }) {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundColor(.red.opacity(0.7))
                                        }
                                    }
                                }
                                .padding(12)
                                .background(.ultraThinMaterial.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }

                            Button(action: { memberNames.append("") }) {
                                Label("Add Another Member", systemImage: "plus")
                                    .font(.subheadline.bold())
                                    .foregroundColor(Color.primaryStart)
                            }
                            .padding(.top, 4)
                        }
                        .padding()
                        .background(.ultraThinMaterial.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 20))

                        // Notice
                        Text("No accounts required. Members are stored locally on your device and can be edited anytime.")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal, 4)

                        // Save Button
                        Button(action: saveGroup) {
                            Text("Create Group")
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
                        .disabled(groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .opacity(groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
                        .padding(.top, 10)
                    }
                    .padding()
                }
            }
            .navigationTitle("New Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }

    private func saveGroup() {
        let cleanMembers = memberNames
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let group = viewModel.createGroup(
            name: groupName,
            description: groupDescription,
            currencyCode: selectedCurrency,
            memberNames: cleanMembers
        )
        if group != nil {
            dismiss()
        }
    }
}
