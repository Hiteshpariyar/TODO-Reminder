// TODO_ReminderApp.swift
// Main entry point for the application
// Supports both Reminders and Splid-inspired offline-first Expense Sharing

import SwiftUI
import SwiftData
import UserNotifications

@main
struct TODO_ReminderApp: App {
    // SwiftData container registering Reminders (Task, Tag) and Expenses (ExpenseGroup, GroupMember, Expense, Settlement)
    var container: ModelContainer = {
        do {
            let schema = Schema([
                Task.self,
                Tag.self,
                ExpenseGroup.self,
                GroupMember.self,
                Expense.self,
                Settlement.self
            ])
            let container = try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: false))
            return container
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    @StateObject private var guestIdentityService = GuestIdentityService.shared
    @StateObject private var syncCoordinator = OfflineSyncCoordinator.shared
    @StateObject private var expenseGroupsViewModel = ExpenseGroupsViewModel()

    init() {
        NotificationService.shared.requestPermission()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .environmentObject(NotificationService.shared)
                .environmentObject(guestIdentityService)
                .environmentObject(syncCoordinator)
                .environmentObject(expenseGroupsViewModel)
        }
    }
}
