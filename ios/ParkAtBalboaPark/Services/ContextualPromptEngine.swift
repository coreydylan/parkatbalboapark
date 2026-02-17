import Foundation

/// Pure logic engine that determines which contextual prompt to show based on profile state.
@MainActor
struct ContextualPromptEngine {

    struct Prompt: Identifiable {
        let id: String
        let icon: String
        let iconColor: String // "accentColor", "orange", "red", "green"
        let title: String
        let message: String
        let actionLabel: String?
        let actionURL: String?
        let dismissable: Bool
        let snoozable: Bool
    }

    /// Returns the highest-priority prompt to show, or nil if none are relevant.
    static func evaluate(profile: UserProfile) -> Prompt? {
        // Priority 1: Permit expired (urgent)
        if profile.permitState == .expired {
            return Prompt(
                id: "permit_expired",
                icon: "exclamationmark.triangle.fill",
                iconColor: "red",
                title: "Permit Expired",
                message: "Your parking permit has expired. You\u{2019}re currently paying per-visit rates.",
                actionLabel: "Renew Permit",
                actionURL: "https://sandiego.thepermitportal.com/Home/Availability",
                dismissable: false,
                snoozable: false
            )
        }

        // Priority 2: Permit expiring soon
        if profile.permitState == .expiringSoon, !profile.isReminderSnoozed {
            let daysLeft: Int
            if let exp = profile.permitExpirationDate {
                daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: exp).day ?? 0
            } else {
                daysLeft = 0
            }
            return Prompt(
                id: "permit_expiring",
                icon: "clock.badge.exclamationmark",
                iconColor: "orange",
                title: "Expiring in \(daysLeft) day\(daysLeft == 1 ? "" : "s")",
                message: "Your parking pass expires soon. Renew to keep your discounted rates.",
                actionLabel: "Renew Now",
                actionURL: "https://sandiego.thepermitportal.com/Home/Availability",
                dismissable: true,
                snoozable: true
            )
        }

        // Priority 3: Day permit ROI suggestion
        if profile.shouldShowDayPermitROI {
            let totalCents = profile.dayPermitCount * (profile.isSDCityResident ? 500 : 1000)
            let passCents = profile.isSDCityResident ? 3000 : 4000
            return Prompt(
                id: "day_permit_roi",
                icon: "lightbulb.fill",
                iconColor: "orange",
                title: "A pass might save you money",
                message: "You\u{2019}ve bought \(profile.dayPermitCount) day permits this month ($\(totalCents / 100)). A monthly pass is $\(passCents / 100).",
                actionLabel: "View Pass Options",
                actionURL: "https://sandiego.thepermitportal.com/Home/Availability",
                dismissable: true,
                snoozable: false
            )
        }

        // Priority 4: Registered but hasn't purchased a pass yet
        if profile.hasPortalAccount && !profile.isVerifiedResident && profile.isSDCityResident && !profile.isReminderSnoozed {
            return Prompt(
                id: "portal_registered_no_pass",
                icon: "ticket.fill",
                iconColor: "accentColor",
                title: "Ready to buy a pass?",
                message: "You\u{2019}ve registered at the permit portal. Purchase your first pass to verify your residency and unlock discounted rates.",
                actionLabel: "Buy a Pass",
                actionURL: "https://sandiego.thepermitportal.com/Home/Availability",
                dismissable: true,
                snoozable: true
            )
        }

        // Priority 5: Deferred residency prompt (remind after 4+ app opens)
        if profile.residencyDeferred && !profile.hasPortalAccount && profile.appOpenCount >= 4 && !profile.isReminderSnoozed {
            return Prompt(
                id: "residency_deferred",
                icon: "person.crop.circle.badge.questionmark",
                iconColor: "accentColor",
                title: "San Diego resident?",
                message: "You might qualify for discounted parking. Tap to set up your profile.",
                actionLabel: nil,
                actionURL: nil,
                dismissable: true,
                snoozable: true
            )
        }

        // Priority 6: Frequent non-resident visitor
        if profile.shouldSuggestPassToVisitor && !profile.isReminderSnoozed {
            return Prompt(
                id: "frequent_visitor",
                icon: "star.fill",
                iconColor: "accentColor",
                title: "Visit often?",
                message: "You\u{2019}ve visited \(profile.visitCount) times. Consider a non-resident pass to save on parking.",
                actionLabel: "View Passes",
                actionURL: "https://sandiego.thepermitportal.com/Home/Availability",
                dismissable: true,
                snoozable: true
            )
        }

        // Priority 7: March 2 awareness (14 days before, for verified residents)
        let march2 = DateComponents(calendar: .current, year: 2026, month: 3, day: 2).date!
        let daysUntilMarch2 = Calendar.current.dateComponents([.day], from: Date(), to: march2).day ?? 999
        if daysUntilMarch2 > 0 && daysUntilMarch2 <= 14 && profile.isVerifiedResident && !profile.isReminderSnoozed {
            return Prompt(
                id: "march2_awareness",
                icon: "calendar.badge.clock",
                iconColor: "accentColor",
                title: "Free parking coming March 2",
                message: "Seven lots become free for verified residents, and enforcement hours shorten to 8 AM \u{2013} 6 PM.",
                actionLabel: nil,
                actionURL: nil,
                dismissable: true,
                snoozable: false
            )
        }

        return nil
    }
}
