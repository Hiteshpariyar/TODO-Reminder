// HomeView.swift
// Main home screen displaying the calendar strip and list of tasks for the selected date

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var calendarVM: CalendarViewModel
    @EnvironmentObject var addTaskVM: AddTaskViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Month/Year header with swipe gestures
            MonthHeaderView(date: calendarVM.selectedDate)
                .padding(.top, 10)
                .gesture(
                    DragGesture(minimumDistance: 30)
                        .onEnded { value in
                            let direction = value.translation.width > 0 ? -1 : 1
                            changeMonth(by: direction)
                        }
                )
            // Horizontal calendar strip
            CalendarStripView(selectedDate: $calendarVM.selectedDate)
                .padding(.vertical, 8)
            // Search bar placeholder (glass style)
            SearchBarView(searchText: .constant(""))
                .padding(.horizontal)
            // Task list
            if calendarVM.tasks.isEmpty {
                EmptyStateView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(calendarVM.tasks, id: \._id) { task in
                            TaskCardView(task: task)
                        }
                    }
                    .padding()
                }
            }
            Spacer(minLength: 0)
        }
        .background(Color.black.ignoresSafeArea())
    }
    
    private func changeMonth(by offset: Int) {
        var components = DateComponents()
        components.month = offset
        if let newDate = Calendar.current.date(byAdding: components, to: calendarVM.selectedDate) {
            calendarVM.selectDate(newDate)
        }
    }
}

// Month header displaying month and year
struct MonthHeaderView: View {
    var date: Date
    var body: some View {
        Text(date, format: Date.FormatStyle().month(.wide).year())
            .font(.largeTitle.bold().rounded())
            .foregroundColor(.white)
    }
}

// Simple glass‑style search bar (functionality not implemented)
struct SearchBarView: View {
    @Binding var searchText: String
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.7))
            TextField("Search tasks…", text: $searchText)
                .foregroundColor(.white)
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
        )
    }
}

// Empty state view when there are no tasks for the selected day
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.badge")
                .font(.system(size: 64))
                .foregroundColor(.white.opacity(0.4))
            Text("No reminders yet")
                .font(.title3.bold().rounded())
                .foregroundColor(.white.opacity(0.9))
        }
        .frame(maxHeight: .infinity)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(CalendarViewModel())
            .environmentObject(AddTaskViewModel())
    }
}

