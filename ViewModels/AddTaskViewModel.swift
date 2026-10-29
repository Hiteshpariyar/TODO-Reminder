// AddTaskViewModel.swift
// Handles creation, editing, and scheduling of Task objects

import SwiftUI
import SwiftData
import UserNotifications

@Observable class AddTaskViewModel {
    // Input fields bound to the UI
    var title: String = ""
    var notes: String = ""
    var selectedTag: Tag?
    var eventDate: Date = Date()
    var eventTime: Date = Date()
    var recurrenceRule: String = "once" // "once" or "yearly"
    var ringtoneName: String = "default"
    var playInSilentMode: Bool = false
    var reminderOffsets: [Int] = [86400] // 1 day before by default
    
    // Services
    private let notificationService = NotificationService.shared
    private let context: ModelContext
    
    init(context: ModelContext = ModelContext()) {
        self.context = context
    }
    
    // Combined date & time into a single Date
    private var combinedDateTime: Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: eventDate)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: eventTime)
        var merged = DateComponents()
        merged.year = dateComponents.year
        merged.month = dateComponents.month
        merged.day = dateComponents.day
        merged.hour = timeComponents.hour
        merged.minute = timeComponents.minute
        merged.second = timeComponents.second
        return calendar.date(from: merged) ?? Date()
    }
    
    func addOffset(days: Int, hours: Int, minutes: Int) {
        let seconds = days * 86400 + hours * 3600 + minutes * 60
        guard seconds > 0 else { return }
        reminderOffsets.append(seconds)
    }
    
    func removeOffset(at index: Int) {
        guard reminderOffsets.indices.contains(index) else { return }
        reminderOffsets.remove(at: index)
    }
    
    func saveTask() {
        let task = Task(
            title: title,
            notes: notes.isEmpty ? nil : notes,
            tagID: selectedTag?.id,
            eventDate: combinedDateTime,
            recurrenceRule: recurrenceRule,
            ringtoneName: ringtoneName,
            playInSilentMode: playInSilentMode,
            reminderOffsets: reminderOffsets
        )
        do {
            context.insert(task)
            try context.save()
            // Schedule notifications
            notificationService.scheduleNotifications(for: task)
        } catch {
            print("Failed to save task: \(error)")
        }
    }
}

