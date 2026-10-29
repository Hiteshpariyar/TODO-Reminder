// CalendarViewModel.swift
// ViewModel responsible for managing calendar state and fetching tasks for the selected date

import SwiftUI
import SwiftData

@Observable class CalendarViewModel {
    // Currently selected date (day-level precision)
    @MainActor @Published var selectedDate: Date = Date()
    
    // All tasks loaded from SwiftData
    @MainActor @Published var tasks: [Task] = []
    
    private var context: ModelContext
    
    init(context: ModelContext = ModelContext()) {
        self.context = context
        loadTasks()
    }
    
    // Load tasks from the persistent store and filter for the selected date
    func loadTasks() {
        let descriptor = FetchDescriptor<Task>(sortBy: [SortDescriptor("eventDate")])
        do {
            let all = try context.fetch(descriptor)
            self.tasks = all.filter { Calendar.current.isDate($0.eventDate, inSameDayAs: selectedDate) && $0.isEnabled }
        } catch {
            print("Failed to fetch tasks: \(error)")
            self.tasks = []
        }
    }
    
    // Update selected date and refresh tasks
    func selectDate(_ date: Date) {
        selectedDate = date
        loadTasks()
    }
}

