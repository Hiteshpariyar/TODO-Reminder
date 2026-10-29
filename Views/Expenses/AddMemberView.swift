// AddMemberView.swift
// Sheet to add a new local member to an existing group

import SwiftUI

public struct AddMemberView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: ExpenseGroupsViewModel

    public let group: ExpenseGroup
    @State private var memberName: String = ""

    public init(group: ExpenseGroup) {
        self.group = group
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundDark.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add Member")
                            .font(.headline)
                            .foregroundColor(.white)

                        TextField("Friend's Name", text: $memberName)
                            .padding()
                            .background(.ultraThinMaterial.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .foregroundColor(.white)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.25), lineWidth: 0.5))

                        Text("Guests can add unregistered members without needing emails, phone numbers, or passwords. Data stays offline on this device.")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.65))
                            .padding(.top, 4)
                    }
                    .padding()
                    .background(.ultraThinMaterial.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                    Button(action: saveMember) {
                        Text("Add to Group")
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
                    .disabled(memberName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(memberName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Add Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }

    private func saveMember() {
        let clean = memberName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        viewModel.addMember(to: group, name: clean)
        dismiss()
    }
}
