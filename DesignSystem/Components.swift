// Components.swift
// Reusable UI components for the Liquid Glass design system

import SwiftUI

// Gradient button with pulsing glow (used for FAB and Save button)
struct GradientButton<Label: View>: View {
    var action: () -> Void
    var label: () -> Label
    var gradient: AngularGradient = GradientFactory.primaryAngular()
    var cornerRadius: CGFloat = 28
    
    var body: some View {
        Button(action: action) {
            label()
                .padding()
                .frame(maxWidth: .infinity)
                .background(gradient)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .modifier(PulsingGlow())
        }
    }
}

// Tag chip with gradient background
struct TagChip: View {
    var name: String
    var startHex: String
    var endHex: String
    var isSelected: Bool = false
    
    var body: some View {
        Text(name)
            .font(.caption.bold().rounded())
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                LinearGradient(colors: [Color(hex: startHex), Color(hex: endHex)], startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.white.opacity(0.5) : Color.clear, lineWidth: 1)
            )
    }
}

// Generic glass‑styled card container
struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 28
    var content: () -> Content
    
    var body: some View {
        content()
            .padding()
            .liquidGlass(cornerRadius: cornerRadius)
    }
}

// Pulsing glow effect (shared with FAB)
struct PulsingGlow: ViewModifier {
    @State private var isAnimating = false
    func body(content: Content) -> some View {
        content
            .shadow(color: Color.primaryStart.opacity(isAnimating ? 0.6 : 0.2), radius: isAnimating ? 30 : 15)
            .scaleEffect(isAnimating ? 1.05 : 1.0)
            .onAppear { withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) { isAnimating.toggle() } }
    }
}

// Helper to convert hex strings to Color (used across the app)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12‑bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24‑bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32‑bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

