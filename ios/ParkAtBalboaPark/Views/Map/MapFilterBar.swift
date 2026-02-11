import SwiftUI

struct MapFilterBar: View {
    @Environment(AppState.self) private var state

    var body: some View {
        @Bindable var state = state

        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    label: "Tram",
                    icon: "tram.fill",
                    isActive: state.mapFilters.showTram
                ) {
                    state.mapFilters.showTram.toggle()
                }

                FilterChip(
                    label: "Restrooms",
                    icon: "toilet",
                    isActive: state.mapFilters.showRestrooms
                ) {
                    state.mapFilters.showRestrooms.toggle()
                }

                FilterChip(
                    label: "Water",
                    icon: "drop.fill",
                    isActive: state.mapFilters.showWater
                ) {
                    state.mapFilters.showWater.toggle()
                }

                FilterChip(
                    label: "EV",
                    icon: "ev.plug.ac.type.2",
                    isActive: state.mapFilters.showEvCharging
                ) {
                    state.mapFilters.showEvCharging.toggle()
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
        .tint(isActive ? .green : .primary)
        .glassEffect(.regular.interactive())
        .sensoryFeedback(.selection, trigger: isActive)
    }
}
