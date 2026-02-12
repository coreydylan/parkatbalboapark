import SwiftUI

struct DestinationSearchView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            List {
                if let selected = state.parking.selectedDestination {
                    Section {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(.red)
                            VStack(alignment: .leading) {
                                Text(selected.displayName)
                                    .font(.subheadline.weight(.medium))
                                Text(selected.area.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Clear") {
                                state.parking.selectDestination(nil)
                            }
                            .font(.subheadline)
                            .foregroundStyle(.red)
                        }
                    } header: {
                        Text("Current Destination")
                    }
                }

                ForEach(sortedAreas, id: \.self) { area in
                    Section {
                        ForEach(filteredByArea(area)) { dest in
                            Button {
                                state.parking.selectDestination(dest)
                                dismiss()
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: dest.type.icon)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .frame(width: 24)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(dest.displayName)
                                            .font(.subheadline)
                                            .foregroundStyle(.primary)
                                        if let address = dest.address {
                                            Text(address)
                                                .font(.caption2)
                                                .foregroundStyle(.tertiary)
                                                .lineLimit(1)
                                        }
                                    }
                                }
                            }
                        }
                    } header: {
                        Text(area.displayName)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search destinations")
            .navigationTitle("Where are you going?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Filtering

    private var filteredDestinations: [Destination] {
        if searchText.isEmpty {
            return state.parking.destinations
        }
        return state.parking.destinations.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var sortedAreas: [DestinationArea] {
        let order: [DestinationArea] = [
            .centralMesa, .palisades, .eastMesa, .floridaCanyon, .morleyField, .panAmerican,
        ]
        let presentAreas = Set(filteredDestinations.map(\.area))
        return order.filter { presentAreas.contains($0) }
    }

    private func filteredByArea(_ area: DestinationArea) -> [Destination] {
        filteredDestinations.filter { $0.area == area }.sorted(by: { $0.name < $1.name })
    }
}
