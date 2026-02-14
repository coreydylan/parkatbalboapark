import SwiftUI

struct MapStylePicker: View {
    @Environment(AppState.self) private var state

    var body: some View {
        @Bindable var mapState = state.map

        Picker("Map Style", selection: $mapState.mapStyle) {
            ForEach(MapStyleOption.allCases) { option in
                Text(option.rawValue).tag(option)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 240)
    }
}
