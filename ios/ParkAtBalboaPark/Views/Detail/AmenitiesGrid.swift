import SwiftUI

/// 2-column grid displaying lot amenities and payment information.
struct AmenitiesGrid: View {
    let lot: ParkingLot
    let recommendation: ParkingRecommendation

    private var amenities: [(icon: String, label: String, detail: String)] {
        var items: [(String, String, String)] = []

        if let capacity = lot.capacity {
            items.append(("car.fill", "\(capacity)", "spaces"))
        }

        if lot.hasEvCharging {
            items.append(("ev.plug.ac.type.2", "EV", "charging"))
        }

        if lot.hasAdaSpaces {
            items.append(("accessibility", "ADA", "spaces"))
        }

        if lot.hasTramStop {
            let tramTime = recommendation.tramTimeMinutes.map { "\($0) min" } ?? ""
            items.append(("tram.fill", "Tram", tramTime))
        }

        return items
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Amenities & Info", systemImage: "info.circle")
                .font(.subheadline.weight(.semibold))

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                ],
                spacing: 10
            ) {
                ForEach(Array(amenities.enumerated()), id: \.offset) { _, amenity in
                    HStack(spacing: 8) {
                        Image(systemName: amenity.icon)
                            .font(.caption)
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(amenity.label)
                                .font(.caption.weight(.semibold))
                            Text(amenity.detail)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .padding(10)
                    .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
                }
            }

            // Payment methods
            HStack(spacing: 4) {
                Image(systemName: "creditcard")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("Payment: ParkMobile, Card, Apple Pay, Google Pay")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 4)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(amenitiesAccessibilityLabel)
    }

    private var amenitiesAccessibilityLabel: String {
        var parts = amenities.map { "\($0.label) \($0.detail)" }
        parts.append("Payment: ParkMobile, Card, Apple Pay, Google Pay")
        return "Amenities: " + parts.joined(separator: ", ")
    }
}
