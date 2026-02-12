import SwiftUI

struct MainSheetContent: View {
    @Environment(AppState.self) private var state
    @Binding var showProfile: Bool
    @Binding var sheetDetent: PresentationDetent

    @State private var isSearching = false
    @State private var showParkingResults = false
    @State private var profileSetupPrompt = false
    @State private var showTripPlanner = false
    @State private var searchText = ""
    @FocusState private var searchFocused: Bool

    private var isCollapsed: Bool {
        sheetDetent == .fraction(0.08)
    }

    private var hasProfile: Bool {
        state.profile.effectiveUserType != nil
    }

    /// After a destination is selected but before "Park Now" / "Plan a Trip"
    private var showDestinationCard: Bool {
        state.parking.selectedDestination != nil && !showParkingResults && !isSearching
    }

    var body: some View {
        VStack(spacing: 0) {
            if isCollapsed {
                // Collapsed: floating pill only, no sheet chrome
                Spacer()
                collapsedPill
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
            } else {
                // Expanded: custom drag handle + search bar + content
                Capsule()
                    .fill(.quaternary)
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                collapsedPill
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                ZStack {
                    if isSearching {
                        destinationList
                            .transition(.opacity.combined(with: .offset(y: 8)))
                    } else if showDestinationCard {
                        destinationCard
                            .transition(.opacity.combined(with: .offset(y: 8)))
                    } else {
                        RecommendationSheet()
                            .transition(.opacity.combined(with: .offset(y: 8)))
                    }
                }
                .animation(.smooth(duration: 0.3), value: isSearching)
                .animation(.smooth(duration: 0.3), value: showDestinationCard)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            if !isCollapsed {
                UnevenRoundedRectangle(
                    topLeadingRadius: 16,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 16
                )
                .fill(.regularMaterial)
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .animation(.smooth(duration: 0.35), value: isCollapsed)
        .sheet(isPresented: $showProfile) {
            ProfileView(showSetupPrompt: profileSetupPrompt)
        }
        .sheet(isPresented: $showTripPlanner) {
            TripPlannerSheet {
                showTripPlanner = false
                commitToParking()
            }
        }
        .onChange(of: showProfile) {
            if !showProfile { profileSetupPrompt = false }
        }
        .onChange(of: state.parking.selectedDestination) {
            if state.parking.selectedDestination == nil {
                showParkingResults = false
            }
        }
    }

    // MARK: - Collapsed Pill / Search Bar

    private var collapsedPill: some View {
        HStack(spacing: 12) {
            pillContent

            if !isCollapsed {
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
                            Image(systemName: "gearshape.fill")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.smooth(duration: 0.3), value: isSearching)
            }
        }
    }

    private var pillContent: some View {
        HStack(spacing: 10) {
            // Search icon + text
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(isCollapsed ? .subheadline : .subheadline)

                if isSearching {
                    TextField("Search destinations", text: $searchText)
                        .font(.subheadline)
                        .focused($searchFocused)
                        .submitLabel(.search)
                } else if let dest = state.parking.selectedDestination {
                    Text(dest.displayName)
                        .foregroundStyle(.primary)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                } else if isCollapsed && !hasProfile {
                    Text("Start Here")
                        .foregroundStyle(.secondary)
                        .font(.subheadline.weight(.medium))
                } else {
                    Text("Where are you headed?")
                        .foregroundStyle(isCollapsed ? .secondary : .tertiary)
                        .font(.subheadline)
                }
            }

            Spacer(minLength: 4)

            // Trailing controls
            if isCollapsed {
                if state.parking.selectedDestination != nil {
                    Button { clearDestination() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                            .font(.subheadline)
                    }
                } else {
                    profileChip
                }
            } else if isSearching && !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .transition(.scale.combined(with: .opacity))
            } else if !isSearching && state.parking.selectedDestination != nil && showParkingResults {
                Button { clearDestination() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .frame(minHeight: isCollapsed ? 28 : 24)
        .padding(.horizontal, isCollapsed ? 12 : 12)
        .padding(.vertical, isCollapsed ? 6 : 9)
        .background {
            if isCollapsed {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.12), radius: 10, y: 3)
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.quaternary.opacity(0.8))
            }
        }
        .clipShape(isCollapsed ? AnyShape(Capsule()) : AnyShape(RoundedRectangle(cornerRadius: 10)))
        .contentShape(isCollapsed ? AnyShape(Capsule()) : AnyShape(RoundedRectangle(cornerRadius: 10)))
        .onTapGesture { handlePillTap() }
        .animation(.smooth(duration: 0.35), value: isCollapsed)
        .accessibilityLabel(
            state.parking.selectedDestination != nil
                ? "Destination: \(state.parking.selectedDestination!.displayName)"
                : "Search for a destination"
        )
    }

    // MARK: - Profile Chip

    @ViewBuilder
    private var profileChip: some View {
        if hasProfile, let userType = state.profile.effectiveUserType {
            Menu {
                // Role switcher
                if state.profile.userRoles.count > 1 {
                    ForEach(
                        Array(state.profile.userRoles).sorted(by: { $0.rawValue < $1.rawValue })
                    ) { role in
                        Button {
                            state.profile.activeCapacity = role
                        } label: {
                            Label {
                                Text(role.label)
                            } icon: {
                                if state.profile.effectiveUserType == role {
                                    Image(systemName: "checkmark")
                                } else {
                                    Image(systemName: role.icon)
                                }
                            }
                        }
                    }
                    Divider()
                }

                Button {
                    showProfile = true
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: userType.icon)
                        .font(.caption2)
                    Text(userType.label)
                        .font(.caption.weight(.medium))
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.quaternary, in: Capsule())
            }
        } else {
            Button {
                profileSetupPrompt = true
                showProfile = true
            } label: {
                Image(systemName: "person.circle")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Pill Tap Logic

    private func handlePillTap() {
        if isSearching { return }

        if isCollapsed && state.parking.selectedDestination != nil {
            // Tapping collapsed pill when destination is set → expand to show card or results
            withAnimation(.smooth(duration: 0.3)) {
                sheetDetent = showParkingResults ? .fraction(0.4) : .fraction(0.5)
            }
            return
        }

        if !hasProfile {
            profileSetupPrompt = true
            showProfile = true
        } else {
            withAnimation(.smooth(duration: 0.3)) {
                activateSearch()
            }
        }
    }

    // MARK: - Destination Card

    private var destinationCard: some View {
        VStack(spacing: 0) {
            if let dest = state.parking.selectedDestination {
                VStack(spacing: 16) {
                    // Destination info
                    VStack(spacing: 6) {
                        Image(systemName: dest.type.icon)
                            .font(.title2)
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 48, height: 48)
                            .background(Color.accentColor.opacity(0.12), in: Circle())

                        Text(dest.displayName)
                            .font(.title3.weight(.semibold))
                            .multilineTextAlignment(.center)

                        Text(dest.area.displayName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        if let address = dest.address {
                            Text(address)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.top, 8)

                    // Action buttons
                    VStack(spacing: 10) {
                        Button {
                            withAnimation(.smooth(duration: 0.3)) {
                                commitToParking()
                            }
                        } label: {
                            Label("Park Now", systemImage: "car.fill")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.accentColor)

                        Button {
                            showTripPlanner = true
                        } label: {
                            Label("Plan a Trip", systemImage: "calendar")
                                .font(.subheadline.weight(.medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.bordered)
                    }

                    // Change destination
                    Button {
                        withAnimation(.smooth(duration: 0.3)) {
                            activateSearch()
                        }
                    } label: {
                        Text("Change destination")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Destination List

    private var destinationList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if state.parking.destinations.isEmpty {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Loading destinations…")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button("Retry") {
                            Task { await state.parking.loadData() }
                        }
                        .font(.subheadline.weight(.medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                } else {
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
                clearDestination()
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

    // MARK: - Actions

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
        // Go to destination card (taller detent) if destination was just selected
        sheetDetent = state.parking.selectedDestination != nil ? .fraction(0.5) : .fraction(0.4)
    }

    private func commitToParking() {
        if state.parking.tripDate == nil {
            state.parking.resetToNow()
        }
        showParkingResults = true
        sheetDetent = .fraction(0.4)
        Task { await state.fetchRecommendations() }
    }

    private func clearDestination() {
        state.parking.selectDestination(nil)
        showParkingResults = false
        withAnimation(.smooth(duration: 0.3)) {
            sheetDetent = .fraction(0.08)
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

// MARK: - Trip Planner Sheet

struct TripPlannerSheet: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Calendar.current.date(
        byAdding: .day, value: 1, to: Date()
    )!
    var onCommit: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.largeTitle)
                            .foregroundStyle(Color.accentColor)
                        Text("Plan Your Visit")
                            .font(.title3.weight(.semibold))
                        Text("Choose a date and set your start and end times.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Date")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)

                        DatePicker(
                            "Date",
                            selection: $selectedDate,
                            in: Date()...,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                    }
                    .padding(.horizontal, 4)

                    VisitTimePicker(isParkNow: false)
                        .padding(.horizontal, 4)

                    Button {
                        state.parking.tripDate = selectedDate
                        onCommit()
                    } label: {
                        Label("Find Parking", systemImage: "car.fill")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.accentColor)
                    .disabled(state.parking.visitDurationMinutes <= 0)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Plan a Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
