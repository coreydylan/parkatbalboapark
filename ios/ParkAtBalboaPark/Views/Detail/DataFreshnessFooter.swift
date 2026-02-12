import SwiftUI

/// Disclaimer footer for the lot detail view.
struct DataFreshnessFooter: View {
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 1)

            Text("All information is subject to change. Updated daily. Always verify lot signage for current rates and rules.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
    }
}
