// Tag.swift
// SwiftData model representing a user-defined tag with gradient colors

import SwiftData
import Foundation

@Model
final class Tag {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    var gradientStart: String // Hex color string, e.g. "#FF6B9D"
    var gradientEnd: String   // Hex color string, e.g. "#C44EFF"

    init(name: String,
         gradientStart: String = "#FF6B9D",
         gradientEnd: String = "#C44EFF") {
        self.name = name
        self.gradientStart = gradientStart
        self.gradientEnd = gradientEnd
    }
}

