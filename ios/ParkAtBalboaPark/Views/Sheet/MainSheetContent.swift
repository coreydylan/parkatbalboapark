import SwiftUI

struct MainSheetContent: View {
    @Environment(AppState.self) private var state
    @Binding var showSearch: Bool
    @Binding var showProfile: Bool
    @Binding var showInfo: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header: info button + search bar + profile button
            HStack(spacing: 12) {
                Button { showInfo = true } label: {
                    Image(systemName: "info.circle")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }

                searchBarButton

                Button { showProfile = true } label: {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            RecommendationSheet()
        }
        .sheet(isPresented: $showSearch) {
            DestinationSearchView()
        }
        .sheet(isPresented: $showProfile) {
            ProfileView()
        }
        .sheet(isPresented: $showInfo) {
            InfoView()
        }
    }

    // MARK: - Search Bar Button

    private var searchBarButton: some View {
        Button { showSearch = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)

                if let dest = state.parking.selectedDestination {
                    Text(dest.displayName)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                } else {
                    Text("Where are you headed?")
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                if state.parking.selectedDestination != nil {
                    Button {
                        state.parking.selectDestination(nil)
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
        .accessibilityLabel(
            state.parking.selectedDestination != nil
                ? "Destination: \(state.parking.selectedDestination!.displayName)"
                : "Search for a destination"
        )
        .accessibilityHint("Opens destination search")
    }
}
