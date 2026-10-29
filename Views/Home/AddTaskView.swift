// AddTaskView.swift
// Sheet to create or edit a Reminder Task

import SwiftUI
import SwiftData

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var eventDate: Date = Date()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("New Reminder")
                            .font(.headline)
                            .foregroundColor(.white)

                        TextField("Title", text: $title)
                            .padding()
                            .background(.ultraThinMaterial.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .foregroundColor(.white)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.25), lineWidth: 0.5))

                        TextField("Notes (optional)", text: $notes)
                            .padding()
                            .background(.ultraThinMaterial.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .foregroundColor(.white)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.25), lineWidth: 0.5))

                        DatePicker("Date & Time", selection: $eventDate)
                            .colorScheme(.dark)
                            .padding(.top, 8)
                    }
                    .padding()
                    .background(.ultraThinMaterial.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                    Button(action: saveTask) {
                        Text("Save Reminder")
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
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Add Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }

    private func saveTask() {
        let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        let task = Task(title: clean, notes: notes.isEmpty ? nil : notes, eventDate: eventDate)
        modelContext.insert(task)
        try? modelContext.save()
        NotificationService.shared.scheduleNotifications(for: task)
        dismiss()
    }
}
