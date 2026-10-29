// NotificationService.swift
// Centralized service for handling local notification permissions and scheduling

import Foundation
import UserNotifications
import SwiftData

final class NotificationService: ObservableObject {
    static let shared = NotificationService()
    private let center = UNUserNotificationCenter.current()
    private init() {}
    
    // Request permission for alerts, sounds, and badge
    func requestPermission() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
                return
            }
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        }
    }
    
    // Schedule all notifications for a given task
    func scheduleNotifications(for task: Task) {
        // First cancel any existing notifications for this task
        cancelNotifications(for: task.id)
        
        for (index, offset) in task.reminderOffsets.enumerated() {
            let notifyDate = task.eventDate.addingTimeInterval(-TimeInterval(offset))
            var dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notifyDate)
            var repeats = false
            if task.recurrenceRule == "yearly" {
                // Omit year component for yearly repeat
                dateComponents.year = nil
                repeats = true
            }
            let content = UNMutableNotificationContent()
            content.title = task.title
            if let tagName = fetchTagName(by: task.tagID) {
                content.body = "\(tagName) – \(relativeTimeString(to: task.eventDate))"
            } else {
                content.body = relativeTimeString(to: task.eventDate)
            }
            // Sound handling – use bundled CAF file or default
            if let sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "\(task.ringtoneName).caf")) {
                content.sound = sound
            } else {
                content.sound = .default
            }
            // For silent mode handling – requires custom sound with appropriate settings, but we set the sound regardless; user can control via system settings.
            let identifier = "\(task.id.uuidString)-\(index)"
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: repeats)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            center.add(request) { error in
                if let error = error {
                    print("Failed to schedule notification \(identifier): \(error)")
                }
            }
        }
    }
    
    // Cancel all pending notifications for a specific task
    func cancelNotifications(for taskId: UUID) {
        center.getPendingNotificationRequests { requests in
            let ids = requests.map { $0.identifier }.filter { $0.hasPrefix(taskId.uuidString) }
            self.center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }
    
    // Helper to fetch tag name from SwiftData store
    private func fetchTagName(by id: UUID?) -> String? {
        guard let id = id else { return nil }
        // Use a lightweight temporary context to fetch tag
        let container = try? ModelContainer(for: Schema([Tag.self]), configurations: ModelConfiguration(isStoredInMemoryOnly: false))
        guard let container = container else { return nil }
        let ctx = ModelContext(container)
        let descriptor = FetchDescriptor<Tag>(predicate: #Predicate { $0.id == id })
        if let tag = try? ctx.fetchOne(descriptor) {
            return tag.name
        }
        return nil
    }
    
    // Produce a human‑readable relative time string (e.g., "2h 15m left")
    private func relativeTimeString(to date: Date) -> String {
        let interval = date.timeIntervalSinceNow
        if interval <= 0 { return "Now" }
        let minutes = Int(interval) / 60
        let hours = minutes / 60
        let days = hours / 24
        if days > 0 {
            return "\(days)d \(hours % 24)h left"
        } else if hours > 0 {
            return "\(hours)h \(minutes % 60)m left"
        } else {
            return "\(minutes)m left"
        }
    }
}

