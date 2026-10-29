// ContentView.swift
// Root view hosting both the Splid-inspired offline-first Expense Sharing module and Reminders

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var expenseGroupsViewModel: ExpenseGroupsViewModel
    @EnvironmentObject var guestService: GuestIdentityService
    @EnvironmentObject var syncCoordinator: OfflineSyncCoordinator

    @StateObject private var calendarVM = CalendarViewModel()
    @StateObject private var addTaskVM = AddTaskViewModel()
    @State private var showingAddTask = false
    @State private var showingSettings = false
    @State private var showingTagsManager = false
    @State private var selectedMainTab: Int = 0

    var body: some View {
        TabView(selection: $selectedMainTab) {
            // Tab 0: Splid-inspired Expense Sharing
            GroupListView()
                .tabItem {
                    Label("Expenses", systemImage: "creditcard.fill")
                }
                .tag(0)

            // Tab 1: Existing Reminders
            NavigationStack {
                HomeView()
                    .environmentObject(calendarVM)
                    .environmentObject(addTaskVM)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: { showingSettings = true }) {
                                Image(systemName: "gearshape")
                                    .foregroundColor(.white)
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: { showingTagsManager = true }) {
                                Image(systemName: "tag")
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .sheet(isPresented: $showingAddTask) {
                        AddTaskView()
                    }
                    .sheet(isPresented: $showingSettings) {
                        SettingsView()
                    }
                    .sheet(isPresented: $showingTagsManager) {
                        TagsManagerView()
                    }
                    .overlay(
                        Button(action: { showingAddTask = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(
                                    AngularGradient(colors: [Color.primaryStart, Color.primaryEnd], center: .center)
                                        .clipShape(Circle())
                                        .shadow(color: .black.opacity(0.3), radius: 15, y: 8)
                                        .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 0.5))
                                )
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    )
            }
            .tabItem {
                Label("Reminders", systemImage: "bell.badge.fill")
            }
            .tag(1)
        }
        .tint(Color.primaryStart)
        .onAppear {
            expenseGroupsViewModel.setContext(modelContext)
        }
    }
}
