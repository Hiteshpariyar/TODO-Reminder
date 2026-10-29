// TaskCardView.swift
// Visual representation of a Task in a glass‑styled card

import SwiftUI

struct TaskCardView: View {
    let task: Task
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(task.title)
                    .font(.title3.bold().rounded())
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "bell.fill")
                    .foregroundColor(.white.opacity(0.8))
            }
            if let notes = task.notes, !notes.isEmpty {
                Text(notes)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
            }
            HStack {
                if let tagName = fetchTagName(by: task.tagID) {
                    Text(tagName)
                        .font(.caption.bold().rounded())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            LinearGradient(colors: [Color(taskTagGradientStart(task: task)), Color(taskTagGradientEnd(task: task))], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(Capsule())
                }
                Spacer()
                Text(task.eventDate, style: .time)
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.15))
                .background(
                    LinearGradient(colors: [Color("PrimaryStart"), Color("PrimaryEnd")], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .opacity(0.12)
                )
                .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.white.opacity(0.3), lineWidth: 0.5))
                .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
        )
    }
    
    // Helper to fetch tag name (uses NotificationService's helper)
    private func fetchTagName(by id: UUID?) -> String? {
        NotificationService.shared.fetchTagName(by: id)
    }
    
    private func taskTagGradientStart(task: Task) -> Color {
        guard let id = task.tagID else { return Color("PrimaryStart") }
        if let tag = NotificationService.shared.fetchTag(by: id) {
            return Color(hex: tag.gradientStart)
        }
        return Color("PrimaryStart")
    }
    
    private func taskTagGradientEnd(task: Task) -> Color {
        guard let id = task.tagID else { return Color("PrimaryEnd") }
        if let tag = NotificationService.shared.fetchTag(by: id) {
            return Color(hex: tag.gradientEnd)
        }
        return Color("PrimaryEnd")
    }
}

// Extensions to convert hex strings to Color
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

