import SwiftUI

/// PreferenceKey that captures expanded card frames keyed by lot slug.
/// Each expanded `LotCardRow` reports its frame in the `"sheet"` coordinate space.
struct CardFramePreferenceKey: PreferenceKey {
    static let defaultValue: [String: CGRect] = [:]

    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}
