import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Onboarding / Settings: is on-device plate logging available?
enum DeviceAIReadiness {
    enum Status: Equatable {
        case available
        case unavailable(reason: String)
        case unknown
    }

    static func current() -> Status {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                return .available
            case .unavailable(let reason):
                return .unavailable(reason: describe(reason))
            @unknown default:
                return .unknown
            }
        }
        return .unavailable(reason: "On-device plate estimates need iOS 26 with Apple Intelligence.")
        #else
        return .unavailable(reason: "This build can’t reach Apple Intelligence.")
        #endif
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private static func describe(_ reason: SystemLanguageModel.Availability.UnavailableReason) -> String {
        switch reason {
        case .deviceNotEligible:
            return "This iPhone doesn’t support on-device Buddy estimates."
        case .appleIntelligenceNotEnabled:
            return "Turn on Apple Intelligence in Settings for smarter plate logs."
        case .modelNotReady:
            return "Apple Intelligence isn’t ready yet on this iPhone."
        @unknown default:
            return "On-device estimates aren’t available right now."
        }
    }
    #endif

    static var headline: String {
        switch current() {
        case .available:
            return "Buddy can read plates on-device"
        case .unavailable, .unknown:
            return "Snap works — smart estimates need Apple Intelligence"
        }
    }

    static var body: String {
        switch current() {
        case .available:
            return "This iPhone can estimate energy from plates on-device. Nothing leaves the device."
        case .unavailable(let reason):
            return "\(reason) You can still snap plates and enter a quick name — Buddy uses a simple offline guess."
        case .unknown:
            return "You can still log plates. Smarter estimates appear when Apple Intelligence is available."
        }
    }
}
