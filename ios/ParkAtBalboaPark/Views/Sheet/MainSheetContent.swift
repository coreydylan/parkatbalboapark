import MapKit
import SwiftUI
import UIKit

struct MainSheetContent: View {
    @Environment(AppState.self) private var state
    @Binding var showProfile: Bool
    @Binding var sheetDetent: PresentationDetent

    @Namespace private var searchNS
    @State private var isSearching = false
    @State private var showParkingResults = false
    @State private var profileSetupPrompt = false
    @State private var showTripPlanner = false
    @State private var searchText = ""
    @State private var showTimePicker = false
    @State private var poiResults: [MKMapItem] = []
    @State private var poiSearchTask: Task<Void, Never>?
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
                Spacer(minLength: 0)
                collapsedPill
                    .padding(.horizontal, 16)
                Spacer(minLength: 0)
            } else if showDestinationCard {
                // Destination card: photo fills the entire sheet
                destinationCard
                    .transition(.opacity.combined(with: .offset(y: 8)))
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
                    } else {
                        RecommendationSheet()
                            .transition(.opacity.combined(with: .offset(y: 8)))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            if !isCollapsed && !showDestinationCard {
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
        .onChange(of: searchText) {
            poiSearchTask?.cancel()
            if searchText.count >= 2 && filteredDestinations.isEmpty {
                poiSearchTask = Task {
                    try? await Task.sleep(for: .milliseconds(400))
                    guard !Task.isCancelled else { return }
                    await searchMapKitPOIs(query: searchText)
                }
            } else {
                poiResults = []
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
                            dismissSearch()
                        }
                        .font(.subheadline.weight(.medium))
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    } else if !showParkingResults {
                        Button { showProfile = true } label: {
                            Image(systemName: "person.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }
        }
    }

    private var pillContent: some View {
        HStack(spacing: 10) {
            // Search icon / branded thumbnail + text
            HStack(spacing: 8) {
                if !isSearching, let dest = state.parking.selectedDestination {
                    // Branded: circular photo thumbnail or type icon
                    destinationPillThumbnail(dest)
                        .matchedGeometryEffect(id: "destName-\(dest.id)", in: searchNS)
                } else {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                        .font(isCollapsed ? .callout.weight(.semibold) : .subheadline)
                }

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
                        .font(.callout.weight(.semibold))
                } else {
                    Text("Where are you headed?")
                        .foregroundStyle(isCollapsed ? .secondary : .tertiary)
                        .font(isCollapsed ? .callout.weight(.semibold) : .subheadline)
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
            } else if !isSearching && showParkingResults {
                HStack(spacing: 6) {
                    timeSummaryChip
                    inlineProfileMenu
                    Button { clearDestination() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .frame(minHeight: isCollapsed ? 40 : 24)
        .padding(.horizontal, isCollapsed ? 16 : 12)
        .padding(.vertical, isCollapsed ? 10 : 9)
        .background {
            if !isCollapsed {
                // No background in collapsed mode — the sheet's glass is enough
            }
        }
        .overlay {
            // Type-colored accent border when destination is selected
            if !isSearching, let dest = state.parking.selectedDestination {
                Group {
                    if isCollapsed {
                        Capsule()
                            .strokeBorder(dest.type.color.opacity(0.4), lineWidth: 1.5)
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(dest.type.color.opacity(0.3), lineWidth: 1.5)
                    }
                }
                .transition(.opacity)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: isCollapsed ? 50 : 10, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: isCollapsed ? 50 : 10, style: .continuous))
        .onTapGesture { handlePillTap() }
        .accessibilityLabel(
            state.parking.selectedDestination != nil
                ? "Destination: \(state.parking.selectedDestination!.displayName)"
                : "Search for a destination"
        )
    }

    // MARK: - Destination Pill Thumbnail

    @ViewBuilder
    private func destinationPillThumbnail(_ dest: Destination) -> some View {
        let size: CGFloat = isCollapsed ? 24 : 28
        if let image = DestinationCard.loadBundledImage(slug: dest.slug) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay(Circle().stroke(dest.type.color.opacity(0.6), lineWidth: 1.5))
        } else {
            // Fallback: type icon in a colored circle
            Image(systemName: dest.type.icon)
                .font(.system(size: size * 0.45))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(dest.type.color.opacity(0.8), in: Circle())
        }
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

    // MARK: - Inline Time & Profile

    private var timeSummaryChip: some View {
        let totalMinutes = state.parking.visitDurationMinutes
        let hours = totalMinutes / 60
        let mins = totalMinutes % 60
        let durationStr: String
        if hours > 0 && mins > 0 {
            durationStr = "\(hours)h\(mins)m"
        } else if hours > 0 {
            durationStr = "\(hours)h"
        } else {
            durationStr = "\(mins)m"
        }

        return Button { showTimePicker.toggle() } label: {
            HStack(spacing: 3) {
                Image(systemName: "clock")
                    .font(.system(size: 9))
                Text(durationStr)
                    .font(.caption2.weight(.medium))
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(.quaternary, in: Capsule())
        }
        .popover(isPresented: $showTimePicker) {
            CompactTimePicker()
                .padding()
                .presentationCompactAdaptation(.popover)
        }
    }

    @ViewBuilder
    private var inlineProfileMenu: some View {
        if let userType = state.profile.effectiveUserType {
            Menu {
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
                Image(systemName: userType.icon)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .frame(width: 22, height: 22)
                    .background(.quaternary, in: Circle())
            }
        }
    }

    // MARK: - Pill Tap Logic

    private func handlePillTap() {
        if isSearching { return }

        if isCollapsed && state.parking.selectedDestination != nil {
            // Tapping collapsed pill when destination is set → expand to show card or results
            withAnimation(.smooth(duration: 0.3)) {
                sheetDetent = .fraction(0.4)
            }
            return
        }

        if !hasProfile {
            profileSetupPrompt = true
            showProfile = true
        } else {
            activateSearch()
        }
    }

    // MARK: - Destination Card

    @State private var cardImage: UIImage?

    private var destinationCard: some View {
        Group {
            if let dest = state.parking.selectedDestination {
                ZStack(alignment: .bottomLeading) {
                    // Background: photo or type-colored fallback
                    if let image = cardImage {
                        GeometryReader { geo in
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipped()
                        }
                    } else {
                        LinearGradient(
                            colors: [
                                dest.type.color.opacity(0.6),
                                dest.type.color.opacity(0.2),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .overlay {
                            Image(systemName: dest.type.icon)
                                .font(.system(size: 40))
                                .foregroundStyle(.white.opacity(0.15))
                        }
                    }

                    // Gradient overlay for text readability
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: .black.opacity(0.15), location: 0.25),
                            .init(color: .black.opacity(0.5), location: 0.5),
                            .init(color: .black.opacity(0.85), location: 1.0),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .allowsHitTesting(false)

                    // Content overlay
                    VStack(alignment: .leading, spacing: 8) {
                        Spacer(minLength: 0)

                        // Destination name
                        Text(dest.displayName)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                            .lineLimit(2)

                        if let address = dest.address {
                            Text(address)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                                .lineLimit(1)
                        }

                        // Side-by-side buttons
                        HStack(spacing: 10) {
                            Button {
                                commitToParking()
                            } label: {
                                Label("Park Now", systemImage: "car.fill")
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color.accentColor)

                            Button {
                                showTripPlanner = true
                            } label: {
                                Label("Plan a Trip", systemImage: "calendar")
                                    .font(.subheadline.weight(.medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                            }
                            .buttonStyle(.bordered)
                            .tint(.white)
                        }

                        // Change destination link
                        Button {
                            activateSearch()
                        } label: {
                            Text("Change destination")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .padding(.top, 12)
                }
                .frame(maxHeight: .infinity)
                .clipShape(UnevenRoundedRectangle(
                    topLeadingRadius: 16,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 16
                ))
                .ignoresSafeArea(edges: .bottom)
                .overlay(alignment: .top) {
                    Capsule()
                        .fill(.white.opacity(0.4))
                        .frame(width: 36, height: 5)
                        .padding(.top, 8)
                }
                .overlay(alignment: .topTrailing) {
                    Button {
                        clearDestination()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .white.opacity(0.3))
                    }
                    .padding(12)
                }
                .task(id: dest.slug) {
                    cardImage = DestinationCard.loadBundledImage(slug: dest.slug)
                    if cardImage == nil {
                        let slug = dest.slug
                        cardImage = await Task.detached {
                            guard let url = Bundle.main.url(forResource: slug, withExtension: "jpg"),
                                  let data = try? Data(contentsOf: url),
                                  let img = UIImage(data: data) else { return nil as UIImage? }
                            return img
                        }.value
                    }
                }
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

                    LazyVStack(spacing: 10) {
                        ForEach(sortedDestinations) { dest in
                            DestinationCard(
                                destination: dest,
                                namespace: searchNS
                            )
                            .onTapGesture {
                                selectDestinationWithAnimation(dest)
                            }
                        }
                    }

                    // MapKit POI fallback when no internal results match
                    if !poiResults.isEmpty {
                        if filteredDestinations.isEmpty {
                            sectionDivider
                        }
                        sectionHeader("Nearby Places")
                        LazyVStack(spacing: 2) {
                            ForEach(poiResults, id: \.self) { item in
                                poiRow(item)
                                    .onTapGesture {
                                        selectDestinationWithAnimation(destinationFromMapItem(item))
                                    }
                            }
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

    private var sectionDivider: some View {
        Divider().padding(.vertical, 4)
    }

    // MARK: - Actions

    private func activateSearch() {
        withAnimation(.smooth(duration: 0.3)) {
            isSearching = true
            searchText = ""
            sheetDetent = .large
        }
        Task {
            try? await Task.sleep(for: .milliseconds(150))
            searchFocused = true
        }
    }

    private func dismissSearch() {
        withAnimation(.smooth(duration: 0.3)) {
            searchFocused = false
            isSearching = false
            searchText = ""
            poiResults = []
            poiSearchTask?.cancel()
            // Go to destination card (taller detent) if destination was just selected
            sheetDetent = .fraction(0.4)
        }
    }

    private func commitToParking() {
        if state.parking.tripDate == nil {
            state.parking.resetToNow()
        }
        showParkingResults = true
        withAnimation(.smooth(duration: 0.25)) {
            sheetDetent = .fraction(0.4)
        }
        // Only fetch if not already pre-fetched when destination was selected
        if state.parking.recommendations.isEmpty {
            Task {
                try? await Task.sleep(for: .milliseconds(100))
                await state.fetchRecommendations()
            }
        }
    }

    private func selectDestinationWithAnimation(_ dest: Destination) {
        state.parking.recordSelection(slug: dest.slug)
        withAnimation(.spring(response: 0.45, dampingFraction: 0.88)) {
            state.parking.selectDestination(dest)
            searchFocused = false
            isSearching = false
            searchText = ""
            poiResults = []
            poiSearchTask?.cancel()
            sheetDetent = .fraction(0.4)
        }
        // Haptic on the moment the card "lands" in the pill
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        // Pre-fetch recommendations so data is ready when "Park Now" is tapped
        state.parking.resetToNow()
        Task { await state.fetchRecommendations() }
    }

    private func clearDestination() {
        state.parking.selectDestination(nil)
        showParkingResults = false
        withAnimation(.smooth(duration: 0.3)) {
            sheetDetent = .fraction(0.08)
        }
    }

    // MARK: - MapKit POI Search

    @MainActor
    private func searchMapKitPOIs(query: String) async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 32.7341, longitude: -117.1446),
            span: MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025)
        )
        request.resultTypes = .pointOfInterest

        do {
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            poiResults = Array(response.mapItems.prefix(10))
        } catch {
            poiResults = []
        }
    }

    private func destinationFromMapItem(_ item: MKMapItem) -> Destination {
        let itemName = item.name ?? "Unknown Place"
        let slug = "poi-" + itemName.lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))

        let type: DestinationType = {
            guard let category = item.pointOfInterestCategory else { return .other }
            switch category {
            case .restaurant, .cafe, .bakery, .brewery, .winery, .foodMarket:
                return .dining
            case .museum:
                return .museum
            case .park, .nationalPark:
                return .garden
            case .theater:
                return .theater
            case .stadium, .fitnessCenter, .golf, .kayaking, .swimming, .tennis:
                return .recreation
            case .zoo, .aquarium, .animalService:
                return .zoo
            default:
                return .other
            }
        }()

        let coordinate = item.location.coordinate
        let address: String? = item.address?.shortAddress

        return Destination(
            id: slug,
            slug: slug,
            name: itemName,
            displayName: itemName,
            area: .centralMesa,
            type: type,
            address: address,
            lat: coordinate.latitude,
            lng: coordinate.longitude
        )
    }

    private func poiCategoryIcon(_ item: MKMapItem) -> String {
        guard let category = item.pointOfInterestCategory else { return "mappin" }
        switch category {
        case .restaurant, .cafe, .bakery, .brewery, .winery, .foodMarket:
            return "fork.knife"
        case .museum:
            return "building.columns"
        case .park, .nationalPark:
            return "leaf"
        case .theater:
            return "theatermasks"
        case .stadium, .fitnessCenter, .golf, .kayaking, .swimming, .tennis:
            return "figure.run"
        case .zoo, .aquarium, .animalService:
            return "tortoise"
        case .store, .pharmacy:
            return "bag"
        case .hotel:
            return "bed.double"
        case .hospital:
            return "cross.case"
        case .parking:
            return "car"
        default:
            return "mappin"
        }
    }

    private func poiCategoryColor(_ item: MKMapItem) -> Color {
        guard let category = item.pointOfInterestCategory else { return .secondary }
        switch category {
        case .restaurant, .cafe, .bakery, .brewery, .winery, .foodMarket:
            return DestinationType.dining.color
        case .museum:
            return DestinationType.museum.color
        case .park, .nationalPark:
            return DestinationType.garden.color
        case .theater:
            return DestinationType.theater.color
        case .stadium, .fitnessCenter, .golf, .kayaking, .swimming, .tennis:
            return DestinationType.recreation.color
        case .zoo, .aquarium, .animalService:
            return DestinationType.zoo.color
        default:
            return .secondary
        }
    }

    private func poiRow(_ item: MKMapItem) -> some View {
        HStack(spacing: 12) {
            // Category icon
            Image(systemName: poiCategoryIcon(item))
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(poiCategoryColor(item).opacity(0.85), in: Circle())

            // Name + address
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name ?? "Unknown")
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)

                if let subtitle = item.address?.shortAddress,
                   !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 4)

            Text("Nearby")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(.quaternary, in: Capsule())
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
    }

    // MARK: - Filtering

    private var sortedDestinations: [Destination] {
        filteredDestinations.sorted { a, b in
            let countA = state.parking.localSelectionCounts[a.slug] ?? 0
            let countB = state.parking.localSelectionCounts[b.slug] ?? 0
            if countA != countB { return countA > countB }
            let rankA = a.popularityRank ?? 999
            let rankB = b.popularityRank ?? 999
            if rankA != rankB { return rankA < rankB }
            return a.name < b.name
        }
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

// MARK: - Trip Planner Sheet

struct TripPlannerSheet: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date()
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

                    if state.parking.visitDurationMinutes <= 0 {
                        Text("Set an end time after your start time")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

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
