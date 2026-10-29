// Task.swift
// SwiftData model representing a reminder task

import SwiftData
import Foundation

@Model
final class Task {
    @Attribute(.unique) var id: UUID = UUID()
    var title: String
    var notes: String?
    var tagID: UUID?
    var eventDate: Date
    var recurrenceRule: String // "once" or "yearly"
    var ringtoneName: String // e.g., "default", "chime"
    var playInSilentMode: Bool
    var reminderOffsets: [Int] // seconds before event
    var createdAt: Date = Date()
    var isEnabled: Bool = true

    init(title: String,
         notes: String? = nil,
         tagID: UUID? = nil,
         eventDate: Date,
         recurrenceRule: String = "once",
         ringtoneName: String = "default",
         playInSilentMode: Bool = false,
         reminderOffsets: [Int] = [86400]) { // default 1 day before
        self.title = title
        self.notes = notes
        self.tagID = tagID
        self.eventDate = eventDate
        self.recurrenceRule = recurrenceRule
        self.ringtoneName = ringtoneName
        self.playInSilentMode = playInSilentMode
        self.reminderOffsets = reminderOffsets
    }
}

