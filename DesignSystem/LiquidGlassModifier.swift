// LiquidGlassModifier.swift
// Reusable view modifier implementing the iOS 27 Liquid Glass design language

import SwiftUI

struct LiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat = 28
    var opacity: Double = 0.15
    var borderColor: Color = Color.white.opacity(0.3)
    var borderWidth: CGFloat = 0.5
    var shadowColor: Color = Color.black.opacity(0.3)
    var shadowRadius: CGFloat = 20
    var shadowYOffset: CGFloat = 10
    var animation: Animation = .spring(response: 0.4, dampingFraction: 0.75)
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(opacity))
                    .background(
                        LinearGradient(colors: [Color("PrimaryStart"), Color("PrimaryEnd")], startPoint: .topLeading, endPoint: .bottomTrailing)
                            .opacity(0.12)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowYOffset)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .animation(animation, value: UUID()) // trigger on state changes
    }
}

extension View {
    func liquidGlass(cornerRadius: CGFloat = 28) -> some View {
        self.modifier(LiquidGlassModifier(cornerRadius: cornerRadius))
    }
}

