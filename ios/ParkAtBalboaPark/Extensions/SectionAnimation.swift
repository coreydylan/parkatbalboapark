import SwiftUI

/// Staggered fade-and-slide animation for detail view sections.
struct SectionAnimationModifier: ViewModifier {
    let index: Int
    let appeared: Bool

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)
            .animation(
                .easeOut(duration: 0.35).delay(Double(index) * 0.08),
                value: appeared
            )
    }
}

extension View {
    func sectionAnimation(index: Int, appeared: Bool) -> some View {
        modifier(SectionAnimationModifier(index: index, appeared: appeared))
    }
}
