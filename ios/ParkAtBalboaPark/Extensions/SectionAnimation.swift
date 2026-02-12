import SwiftUI

/// Staggered fade-and-slide animation for detail view sections.
/// Groups sections in batches of 3 to reduce independent animation tracks.
struct SectionAnimationModifier: ViewModifier {
    let index: Int
    let appeared: Bool

    private var group: Int { min(index / 3, 2) }

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)
            .animation(
                .easeOut(duration: 0.3).delay(Double(group) * 0.1),
                value: appeared
            )
    }
}

extension View {
    func sectionAnimation(index: Int, appeared: Bool) -> some View {
        modifier(SectionAnimationModifier(index: index, appeared: appeared))
    }
}
