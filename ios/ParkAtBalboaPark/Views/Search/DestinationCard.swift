import SwiftUI
import UIKit

/// Rich destination card for search results (~110pt tall).
/// Shows bundled photo imagery with gradient overlay, destination name, area badge, hours, and type icon.
struct DestinationCard: View {
    let destination: Destination
    let namespace: Namespace.ID

    static var imageCache: [String: UIImage] = [:]

    @State private var loadedImage: UIImage?
    @State private var appeared = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background: bundled photo or type-colored fallback
            backgroundLayer

            // Gradient for text readability
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: .black.opacity(0.15), location: 0.3),
                    .init(color: .black.opacity(0.75), location: 1.0),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)

            // Content overlay
            VStack(alignment: .leading, spacing: 6) {
                Spacer(minLength: 0)

                // Area badge
                Text(destination.area.displayName)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(destination.type.color.opacity(0.85), in: Capsule())

                // Name
                Text(destination.displayName)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .matchedGeometryEffect(id: "destName-\(destination.id)", in: namespace)

                // Bottom row: type icon + hours
                HStack(spacing: 8) {
                    Label(destination.type.displayLabel, systemImage: destination.type.icon)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.8))

                    if let hours = destination.hours {
                        Text("\u{00b7}")
                            .foregroundStyle(.white.opacity(0.5))
                        Label(hours, systemImage: "clock")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white.opacity(0.8))
                    }

                    Spacer()
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 16)
            .padding(.top, 10)
        }
        .frame(height: 130)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
        .opacity(appeared ? 1 : 0.85)
        .scaleEffect(appeared ? 1 : 0.97)
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) {
                appeared = true
            }
        }
        .task {
            if let cached = Self.imageCache[destination.slug] {
                loadedImage = cached
            } else {
                // Do file I/O off the main actor, then cache on main
                let slug = destination.slug
                let image = await Task.detached {
                    guard let url = Bundle.main.url(forResource: slug, withExtension: "jpg"),
                          let data = try? Data(contentsOf: url),
                          let img = UIImage(data: data) else { return nil as UIImage? }
                    return img
                }.value
                if let image {
                    Self.imageCache[slug] = image
                    loadedImage = image
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint("Double tap to select this destination")
    }

    // MARK: - Background

    @ViewBuilder
    private var backgroundLayer: some View {
        if let image = loadedImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .transition(.opacity)
        } else {
            // Type-colored gradient fallback (shown while loading)
            LinearGradient(
                colors: [
                    destination.type.color.opacity(0.6),
                    destination.type.color.opacity(0.2),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay {
                Image(systemName: destination.type.icon)
                    .font(.system(size: 36))
                    .foregroundStyle(.white.opacity(0.15))
            }
        }
    }

    // MARK: - Image Loading

    /// Load a bundled destination image from the app bundle ({slug}.jpg).
    static func loadBundledImage(slug: String) -> UIImage? {
        if let cached = imageCache[slug] { return cached }
        if let url = Bundle.main.url(forResource: slug, withExtension: "jpg"),
           let data = try? Data(contentsOf: url),
           let image = UIImage(data: data) {
            imageCache[slug] = image
            return image
        }
        return nil
    }

    // MARK: - Accessibility

    private var accessibilityDescription: String {
        var parts = [destination.displayName, destination.area.displayName]
        if let hours = destination.hours {
            parts.append("Hours: \(hours)")
        }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Display Label for Type

extension DestinationType {
    var displayLabel: String {
        switch self {
        case .museum: "Museum"
        case .garden: "Garden"
        case .theater: "Theater"
        case .landmark: "Landmark"
        case .recreation: "Recreation"
        case .dining: "Dining"
        case .zoo: "Zoo"
        case .other: "Other"
        }
    }
}
