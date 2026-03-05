//
//  ReducedMotionHelper.swift
//  Daily Joy
//
//  Created by Amadeus Jackson on 12/11/25.
//

import SwiftUI

// MARK: - Accessibility Environment Helper
extension EnvironmentValues {
    var accessibilityReduceMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }
}

// MARK: - Interaction Sounds Environment Helper
private struct InteractionSoundsEnabledKey: EnvironmentKey {
    static let defaultValue: Bool = true
}

extension EnvironmentValues {
    var interactionSoundsEnabled: Bool {
        get { self[InteractionSoundsEnabledKey.self] }
        set { self[InteractionSoundsEnabledKey.self] = newValue }
    }
}

// MARK: - Accessible Animation Modifier
struct AccessibleAnimation: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    let animation: Animation
    
    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content.animation(animation, value: UUID())
        }
    }
}

extension View {
    func accessibleAnimation(_ animation: Animation = .default) -> some View {
        modifier(AccessibleAnimation(animation: animation))
    }
}

// MARK: - Accessible Transition
extension AnyTransition {
    static func accessible(
        normal: AnyTransition,
        reduced: AnyTransition = .opacity
    ) -> AnyTransition {
        UIAccessibility.isReduceMotionEnabled ? reduced : normal
    }
}

// MARK: - High Contrast Support
extension Color {
    static func adaptiveColor(
        normal: Color,
        highContrast: Color
    ) -> Color {
        UIAccessibility.isDarkerSystemColorsEnabled ? highContrast : normal
    }
}
