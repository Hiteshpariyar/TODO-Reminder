// Gradients.swift
// Centralized gradient definitions for the Liquid Glass design system

import SwiftUI

extension Color {
    static let primaryStart = Color(hex: "#FF6B9D") // pink
    static let primaryEnd   = Color(hex: "#C44EFF") // purple
    static let secondaryStart = Color(hex: "#00D9FF") // cyan
    static let secondaryEnd   = Color(hex: "#00FFA3") // mint
    static let accentStart = Color(hex: "#FFB84D") // amber
    static let accentEnd   = Color(hex: "#FF6B6B") // coral
    static let backgroundDark = Color(hex: "#0A0A0F")
    static let backgroundLight = Color.white
}

// Helper to provide AngularGradient for selected states
struct GradientFactory {
    static func primaryAngular() -> AngularGradient {
        AngularGradient(colors: [Color.primaryStart, Color.primaryEnd], center: .center)
    }
    static func secondaryLinear() -> LinearGradient {
        LinearGradient(colors: [Color.secondaryStart, Color.secondaryEnd], startPoint: .leading, endPoint: .trailing)
    }
    static func accentLinear() -> LinearGradient {
        LinearGradient(colors: [Color.accentStart, Color.accentEnd], startPoint: .leading, endPoint: .trailing)
    }
}

