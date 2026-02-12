import Charts
import SwiftUI

/// Mini elevation profile chart using SwiftUI Charts.
struct ElevationChartView: View {
    let elevations: [Double]

    private var elevationsFeet: [Double] {
        elevations.map { $0 * 3.281 }
    }

    private var gainFeet: Int {
        var gain: Double = 0
        for i in 1..<elevations.count {
            let diff = elevations[i] - elevations[i - 1]
            if diff > 0 { gain += diff }
        }
        return Int(gain * 3.281)
    }

    private var lossFeet: Int {
        var loss: Double = 0
        for i in 1..<elevations.count {
            let diff = elevations[i] - elevations[i - 1]
            if diff < 0 { loss += abs(diff) }
        }
        return Int(loss * 3.281)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Elevation Profile", systemImage: "mountain.2.fill")
                .font(.subheadline.weight(.semibold))

            Chart {
                ForEach(Array(elevationsFeet.enumerated()), id: \.offset) { index, elevation in
                    AreaMark(
                        x: .value("Distance", index),
                        y: .value("Elevation", elevation)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.accentColor.opacity(0.3), Color.accentColor.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("Distance", index),
                        y: .value("Elevation", elevation)
                    )
                    .foregroundStyle(Color.accentColor)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .trailing) { value in
                    AxisValueLabel {
                        if let ft = value.as(Double.self) {
                            Text("\(Int(ft))ft")
                                .font(.caption2)
                        }
                    }
                }
            }
            .frame(height: 80)

            // Summary
            HStack(spacing: 16) {
                Label("\(gainFeet)ft gain", systemImage: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if lossFeet > 0 {
                    Label("\(lossFeet)ft loss", systemImage: "arrow.down.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(elevationAccessibilityLabel)
    }

    private var elevationAccessibilityLabel: String {
        if lossFeet > 0 {
            return "Elevation profile: \(gainFeet) feet gain, \(lossFeet) feet loss"
        }
        return "Elevation profile: \(gainFeet) feet gain"
    }
}
