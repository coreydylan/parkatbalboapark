import SwiftUI

struct StreetMeterMarkerView: View {
    let meterCount: Int
    let markerColor: StreetSegment.MarkerColor

    private var fillColor: Color {
        switch markerColor {
        case .free: .green
        case .cheap: .blue
        case .moderate: .orange
        case .expensive: .red
        }
    }

    private var size: CGFloat {
        switch meterCount {
        case 1...4: 20
        case 5...14: 24
        case 15...29: 28
        default: 32
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(fillColor.opacity(0.85))
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(.white, lineWidth: 1.5)
                )
                .shadow(color: fillColor.opacity(0.3), radius: 2)

            Text("\(meterCount)")
                .font(.system(size: size * 0.38, weight: .bold))
                .foregroundStyle(.white)
        }
        .accessibilityLabel("\(meterCount) street meter\(meterCount == 1 ? "" : "s")")
    }
}
