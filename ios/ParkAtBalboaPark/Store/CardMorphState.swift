import MapKit
import SwiftUI

/// Observable state driving the hero morph animation between expanded card and fullscreen overlay.
/// Separated from `AppState` for single responsibility — only morph animation concerns live here.
@MainActor @Observable
class CardMorphState {
    /// Which lot is currently fullscreen (nil = overlay not active).
    var fullscreenLotSlug: String? = nil

    /// Interactive dismiss progress: 0 = fullscreen, 1 = dismissed back to card position.
    var dismissProgress: CGFloat = 0 {
        didSet {
            dismissProgress = min(max(dismissProgress, 0), 1)
        }
    }

    /// True while the user's finger is down during a dismiss drag gesture.
    var isDragging: Bool = false

    /// Frame of the expanded card captured via PreferenceKey, in the sheet coordinate space.
    var expandedCardFrame: CGRect = .zero

    /// Shared Look Around scene cache — cards write, overlay reads (no refetch).
    /// `MKLookAroundScene` is a reference type so `LookAroundPreview` reuses without reloading.
    var sceneCache: [String: MKLookAroundScene] = [:]

    /// Corner radius interpolated from 0 (fullscreen) to 20 (card).
    var cornerRadius: CGFloat {
        20 * dismissProgress
    }

    /// GPU-friendly scale transform during drag (scales down to 85% at full dismiss).
    var dismissScale: CGFloat {
        1.0 - (dismissProgress * 0.15)
    }

    /// GPU-friendly vertical offset during drag (slides down 200pt at full dismiss).
    var dismissOffsetY: CGFloat {
        dismissProgress * 200
    }

    /// Interpolates between the expanded card frame and full container.
    func morphFrame(in containerSize: CGSize) -> CGRect {
        let fullFrame = CGRect(origin: .zero, size: containerSize)
        let t = dismissProgress

        return CGRect(
            x: fullFrame.minX + (expandedCardFrame.minX - fullFrame.minX) * t,
            y: fullFrame.minY + (expandedCardFrame.minY - fullFrame.minY) * t,
            width: fullFrame.width + (expandedCardFrame.width - fullFrame.width) * t,
            height: fullFrame.height + (expandedCardFrame.height - fullFrame.height) * t
        )
    }
}
