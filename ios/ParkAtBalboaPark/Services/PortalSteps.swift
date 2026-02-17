import Foundation

// MARK: - Portal Flow

enum PortalFlow: String, Identifiable {
    case registration
    case purchase

    var id: String { rawValue }

    var url: URL {
        switch self {
        case .registration:
            URL(string: "https://sandiego.thepermitportal.com/Register/Create")!
        case .purchase:
            URL(string: "https://sandiego.thepermitportal.com/Home/Availability")!
        }
    }

    var title: String {
        switch self {
        case .registration: "Register for Resident Rates"
        case .purchase: "Buy a Pass or Permit"
        }
    }

    var icon: String {
        switch self {
        case .registration: "person.badge.plus"
        case .purchase: "ticket.fill"
        }
    }

    var steps: [PortalStep] {
        switch self {
        case .registration: PortalSteps.registration
        case .purchase: PortalSteps.purchase
        }
    }
}

// MARK: - Portal Step

struct PortalStep: Identifiable {
    let id: String
    let urlPattern: String
    let title: String
    let message: String
    let icon: String
}

// MARK: - Step Definitions

enum PortalSteps {
    static let registration: [PortalStep] = [
        PortalStep(
            id: "reg-create",
            urlPattern: "Register/Create",
            title: "Create Your Account",
            message: "Enter your email and password. Registration costs $5 one-time.",
            icon: "person.badge.plus"
        ),
        PortalStep(
            id: "reg-verify",
            urlPattern: "Register/Verify|Account/Verify",
            title: "Verify Your Email",
            message: "Check your email for a verification link, then come back here.",
            icon: "envelope.badge"
        ),
        PortalStep(
            id: "reg-login",
            urlPattern: "Account/Login|Login",
            title: "Sign In",
            message: "Log in with the email and password you just created.",
            icon: "key.fill"
        ),
        PortalStep(
            id: "reg-payment",
            urlPattern: "Register/Payment|Payment",
            title: "Pay Registration Fee",
            message: "Enter your payment info for the $5 one-time registration fee.",
            icon: "creditcard.fill"
        ),
        PortalStep(
            id: "reg-confirm",
            urlPattern: "Register/Confirmation|Confirmation|Success",
            title: "You\u{2019}re Registered!",
            message: "Your account is set up. You can now purchase parking at resident rates.",
            icon: "checkmark.seal.fill"
        ),
    ]

    static let purchase: [PortalStep] = [
        PortalStep(
            id: "buy-availability",
            urlPattern: "Home/Availability",
            title: "Choose Your Permit",
            message: "Select a parking permit type \u{2014} day permit, monthly, quarterly, or annual pass.",
            icon: "ticket.fill"
        ),
        PortalStep(
            id: "buy-login",
            urlPattern: "Account/Login|Login",
            title: "Sign In",
            message: "Log in to your permit portal account to continue.",
            icon: "key.fill"
        ),
        PortalStep(
            id: "buy-vehicle",
            urlPattern: "Vehicle|LicensePlate",
            title: "Vehicle Information",
            message: "Enter your license plate number. Your permit is tied to your plate \u{2014} no physical tag needed.",
            icon: "car.fill"
        ),
        PortalStep(
            id: "buy-residency",
            urlPattern: "Residency|Upload|Document",
            title: "Proof of Residency",
            message: "Upload a photo of your driver\u{2019}s license, vehicle registration, or utility bill. Verification takes 1\u{2013}2 business days.",
            icon: "doc.text.fill"
        ),
        PortalStep(
            id: "buy-payment",
            urlPattern: "Payment|Checkout",
            title: "Payment",
            message: "Enter your payment details to complete your purchase.",
            icon: "creditcard.fill"
        ),
        PortalStep(
            id: "buy-confirm",
            urlPattern: "Confirmation|Success|Receipt",
            title: "Purchase Complete!",
            message: "Your permit is active. It\u{2019}s tied to your license plate \u{2014} just park and go.",
            icon: "checkmark.seal.fill"
        ),
    ]

    /// Simplified steps for "Not yet — just create an account" path
    static let registrationOnly: [PortalStep] = [
        PortalStep(
            id: "reg-create",
            urlPattern: "Register/Create",
            title: "Create Your Account",
            message: "Enter your email and choose a password. Registration costs $5 one-time.",
            icon: "person.badge.plus"
        ),
        PortalStep(
            id: "reg-verify",
            urlPattern: "Register/Verify|Account/Verify",
            title: "Verify Your Email",
            message: "Check your email for a verification link, then come back here.",
            icon: "envelope.badge"
        ),
        PortalStep(
            id: "reg-payment",
            urlPattern: "Register/Payment|Payment",
            title: "Pay Registration Fee",
            message: "Enter your payment info for the $5 one-time registration fee. That\u{2019}s it for today!",
            icon: "creditcard.fill"
        ),
    ]

    static let fallback = PortalStep(
        id: "fallback",
        urlPattern: "",
        title: "Permit Portal",
        message: "You\u{2019}re on the City of San Diego\u{2019}s permit portal. Browse freely!",
        icon: "globe"
    )

    static func findStep(for url: URL?, in steps: [PortalStep]) -> PortalStep {
        guard let url else { return fallback }
        let urlString = url.absoluteString

        for step in steps {
            if urlString.range(of: step.urlPattern, options: .regularExpression) != nil {
                return step
            }
        }

        return fallback
    }

    static func stepNumber(for step: PortalStep, in steps: [PortalStep]) -> Int? {
        guard let index = steps.firstIndex(where: { $0.id == step.id }) else { return nil }
        return index + 1
    }
}
