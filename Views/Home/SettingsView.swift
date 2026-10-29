// SettingsView.swift
// Settings view for application preferences

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    Text("App Preferences")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("Splid-inspired offline-first expense sharing and reminders application.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }
}
