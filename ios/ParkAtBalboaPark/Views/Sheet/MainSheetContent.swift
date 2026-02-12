import SwiftUI

struct MainSheetContent: View {
    @Environment(AppState.self) private var state
    @Binding var showProfile: Bool
    @Binding var sheetDetent: PresentationDetent

    @State private var isSearching = false
    @State private var searchText = ""
    @FocusState private var searchFocused: Bool
    @Namespace private var sheetNamespace

    var body: some View {
        VStack(spacing: 0) {
            headerBar
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

            // Crossfade between search and recommendations
            ZStack {
                if isSearching {
                    destinationList
                        .transition(.opacity.combined(with: .offset(y: 8)))
                } else {
                    RecommendationSheet()
                        .transition(.opacity.combined(with: .offset(y: 8)))
                }
            }
            .animation(.smooth(duration: 0.3), value: isSearching)
        }
        .sheet(isPresented: $showProfile) {
            ProfileView()
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack(spacing: 12) {
            searchBar

            ZStack {
                if isSearching {
                    Button("Cancel") {
                        withAnimation(.smooth(duration: 0.3)) {
                            dismissSearch()
                        }
                    }
                    .font(.subheadline.weight(.medium))
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                } else {
                    Button { showProfile = true } label: {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.smooth(duration: 0.3), value: isSearching)
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.subheadline)

            if isSearching {
                TextField("Search destinations", text: $searchText)
                    .font(.subheadline)
                    .focused($searchFocused)
                    .submitLabel(.search)
            } else if let dest = state.parking.selectedDestination {
                Text(dest.displayName)
                    .foregroundStyle(.primary)
                    .font(.subheadline)
                    .lineLimit(1)
            } else {
                Text("Where are you headed?")
                    .foregroundStyle(.tertiary)
                    .font(.subheadline)
            }

            Spacer()

            if isSearching && !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .transition(.scale.combined(with: .opacity))
            } else if !isSearching && state.parking.selectedDestination != nil {
                Button {
                    state.parking.selectDestination(nil)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(.quaternary.opacity(0.8), in: RoundedRectangle(cornerRadius: 10))
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .onTapGesture {
            if !isSearching {
                withAnimation(.smooth(duration: 0.3)) {
                    activateSearch()
                }
            }
        }
        .accessibilityLabel(
            state.parking.selectedDestination != nil
                ? "Destination: \(state.parking.selectedDestination!.displayName)"
                : "Search for a destination"
        )
    }

    // MARK: - Destination List

    private var destinationList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if let selected = state.parking.selectedDestination {
                    currentDestinationRow(selected)
                    sectionDivider
                }

                ForEach(sortedAreas, id: \.self) { area in
                    sectionHeader(area.displayName)

                    ForEach(filteredByArea(area)) { dest in
                        destinationRow(dest)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollIndicators(.hidden)
    }

    private func currentDestinationRow(_ dest: Destination) -> some View {
        HStack {
            Image(systemName: "mappin.circle.fill")
                .foregroundStyle(.red)
            VStack(alignment: .leading) {
                Text(dest.displayName)
                    .font(.subheadline.weight(.medium))
                Text(dest.area.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Clear") {
                state.parking.selectDestination(nil)
                withAnimation(.smooth(duration: 0.3)) {
                    dismissSearch()
                }
            }
            .font(.subheadline)
            .foregroundStyle(.red)
        }
        .padding(.vertical, 10)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 16)
            .padding(.bottom, 6)
    }

    private func destinationRow(_ dest: Destination) -> some View {
        Button {
            state.parking.selectDestination(dest)
            withAnimation(.smooth(duration: 0.3)) {
                dismissSearch()
            }
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
                Spacer()
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
    }

    private var sectionDivider: some View {
        Divider().padding(.vertical, 4)
    }

    // MARK: - Search Logic

    private func activateSearch() {
        isSearching = true
        searchText = ""
        sheetDetent = .large
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            searchFocused = true
        }
    }

    private func dismissSearch() {
        searchFocused = false
        isSearching = false
        searchText = ""
        sheetDetent = .fraction(0.4)
    }

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
