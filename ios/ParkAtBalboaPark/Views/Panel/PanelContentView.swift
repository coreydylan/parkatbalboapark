import SwiftUI

struct PanelContentView: View {
    @Environment(AppState.self) private var state
    @FocusState private var searchFocused: Bool
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            panelHeader
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

            switch state.panelMode {
            case .recommendations:
                RecommendationSheet()
            case .search:
                searchResults
            case .profile:
                profileContent
            }
        }
        .onChange(of: state.panelMode) { _, newMode in
            if newMode == .search {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    searchFocused = true
                }
            } else {
                searchFocused = false
            }
        }
        .onChange(of: state.sheetDetent) { _, newDetent in
            // Drag down from search → cancel search
            if state.panelMode == .search && newDetent != .full {
                cancelSearch()
            }
            // Drag down from profile → close profile
            if state.panelMode == .profile && newDetent == .peek {
                state.panelMode = .recommendations
            }
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var panelHeader: some View {
        switch state.panelMode {
        case .recommendations:
            recommendationsHeader
        case .search:
            searchHeader
        case .profile:
            profileHeader
        }
    }

    // Search bar button + profile avatar (Apple Maps style)
    private var recommendationsHeader: some View {
        HStack(spacing: 12) {
            Button {
                state.panelMode = .search
                state.sheetDetent = .full
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)

                    if let dest = state.selectedDestination {
                        Text(dest.displayName)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    } else {
                        Text("Where are you headed?")
                            .foregroundStyle(.tertiary)
                    }

                    Spacer()

                    if state.selectedDestination != nil {
                        Button {
                            state.selectedDestination = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(.quaternary.opacity(0.8), in: RoundedRectangle(cornerRadius: 10))
            }

            Button {
                state.panelMode = .profile
                state.sheetDetent = .half
            } label: {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // Active search field + cancel
    private var searchHeader: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                TextField("Where are you headed?", text: $searchText)
                    .font(.subheadline)
                    .focused($searchFocused)
                    .submitLabel(.search)
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(.quaternary.opacity(0.8), in: RoundedRectangle(cornerRadius: 10))

            Button("Cancel") {
                cancelSearch()
            }
            .font(.subheadline)
        }
    }

    // Profile close button
    private var profileHeader: some View {
        HStack {
            Text("Profile")
                .font(.headline)
            Spacer()
            Button {
                state.panelMode = .recommendations
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Search Results

    private var searchResults: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                // Current destination
                if let selected = state.selectedDestination {
                    Button {
                        state.selectedDestination = nil
                    } label: {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(.red)
                            Text(selected.displayName)
                                .foregroundStyle(.primary)
                            Spacer()
                            Text("Clear")
                                .foregroundStyle(.red)
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }

                    Divider().padding(.horizontal, 16)
                }

                // Grouped destinations
                ForEach(sortedAreas, id: \.self) { area in
                    Text(area.displayName.uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 4)

                    ForEach(filteredByArea(area)) { dest in
                        Button { selectDestination(dest) } label: {
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
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            .padding(.bottom, 120)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Profile Content

    private var profileContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.secondary)

                // Roles
                VStack(alignment: .leading, spacing: 12) {
                    Text("I am a...")
                        .font(.subheadline.weight(.semibold))

                    ForEach(UserType.allCases) { type in
                        HStack {
                            Image(systemName: type.icon)
                                .foregroundStyle(state.userRoles.contains(type) ? .green : .secondary)
                                .frame(width: 24)
                            VStack(alignment: .leading) {
                                Text(type.label)
                                    .font(.subheadline)
                                Text(type.description)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { state.userRoles.contains(type) },
                                set: { _ in state.toggleRole(type) }
                            ))
                            .tint(.green)
                        }
                    }
                }

                // Active role
                if state.userRoles.count > 1 {
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("For this visit")
                            .font(.subheadline.weight(.semibold))
                        ForEach(Array(state.userRoles).sorted { $0.rawValue < $1.rawValue }) { role in
                            Button {
                                state.activeCapacity = role
                            } label: {
                                HStack {
                                    Image(systemName: role.icon)
                                    Text(role.label)
                                    Spacer()
                                    if state.activeCapacity == role {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.green)
                                    }
                                }
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }

                // Parking pass
                if state.userRoles.contains(.resident) {
                    Divider()
                    Toggle(isOn: Binding(
                        get: { state.hasPass },
                        set: { state.hasPass = $0 }
                    )) {
                        Label("Parking Pass", systemImage: "creditcard.fill")
                            .font(.subheadline)
                    }
                    .tint(.green)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Actions

    private func selectDestination(_ dest: Destination) {
        state.selectedDestination = dest
        searchText = ""
        searchFocused = false
        state.panelMode = .recommendations
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            state.sheetDetent = .half
        }
    }

    private func cancelSearch() {
        searchText = ""
        searchFocused = false
        state.panelMode = .recommendations
    }

    // MARK: - Filtering

    private var filteredDestinations: [Destination] {
        if searchText.isEmpty { return state.destinations }
        return state.destinations.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var sortedAreas: [DestinationArea] {
        let order: [DestinationArea] = [.centralMesa, .palisades, .eastMesa, .floridaCanyon, .morleyField, .panAmerican]
        let present = Set(filteredDestinations.map(\.area))
        return order.filter { present.contains($0) }
    }

    private func filteredByArea(_ area: DestinationArea) -> [Destination] {
        filteredDestinations.filter { $0.area == area }.sorted { $0.name < $1.name }
    }
}
