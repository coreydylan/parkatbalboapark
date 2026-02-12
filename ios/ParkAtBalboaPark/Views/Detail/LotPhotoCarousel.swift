import MapKit
import SwiftUI

/// Look Around preview header with a background fade into content.
struct LotPhotoCarousel: View {
    let scene: MKLookAroundScene?

    var body: some View {
        if let scene {
            LookAroundPreview(initialScene: scene)
                .frame(height: 260)
                .overlay(alignment: .bottom) {
                    backgroundFade
                }
                .accessibilityLabel("Look Around preview of parking lot")
        } else {
            fallbackGradient
                .frame(height: 160)
                .overlay(alignment: .bottom) {
                    backgroundFade
                }
                .accessibilityLabel("Parking lot image placeholder")
        }
    }

    private var backgroundFade: some View {
        LinearGradient(
            colors: [.clear, Color(.systemBackground)],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 60)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var fallbackGradient: some View {
        LinearGradient(
            colors: [Color.accentColor.opacity(0.3), Color.accentColor.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            Image(systemName: "car.fill")
                .font(.largeTitle)
                .foregroundStyle(.white.opacity(0.3))
        }
    }
}
