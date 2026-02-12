import SwiftUI

struct MapFilterBar: View {
    @Environment(AppState.self) private var state

    var body: some View {
        @Bindable var mapState = state.map

        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    label: "Tram",
                    icon: "tram.fill",
                    isActive: state.map.filters.showTram
                ) {
                    state.map.filters.showTram.toggle()
                }

                FilterChip(
                    label: "Restrooms",
                    icon: "toilet",
                    isActive: state.map.filters.showRestrooms
                ) {
                    state.map.filters.showRestrooms.toggle()
                }

                FilterChip(
                    label: "Water",
                    icon: "drop.fill",
                    isActive: state.map.filters.showWater
                ) {
                    state.map.filters.showWater.toggle()
                }

                FilterChip(
                    label: "EV",
                    icon: "ev.plug.ac.type.2",
                    isActive: state.map.filters.showEvCharging
                ) {
                    state.map.filters.showEvCharging.toggle()
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

struct FilterChip: View {
    let label: String
    let icon: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(label, systemImage: icon)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .tint(isActive ? Color.accentColor : .primary)
        .glassEffect(.regular.interactive())
        .sensoryFeedback(.selection, trigger: isActive)
        .accessibilityAddTraits(.isToggle)
        .accessibilityValue(isActive ? "On" : "Off")
    }
}
