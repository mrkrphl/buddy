import SwiftData
import SwiftUI
import UIKit

struct RootView: View {
    @Query private var prefs: [BuddyPreferences]
    @Environment(\.modelContext) private var context

    var body: some View {
        Group {
            if let p = prefs.first, p.hasSeenOnboarding {
                TodayView()
            } else {
                OnboardingView {
                    ensurePrefs().hasSeenOnboarding = true
                    try? context.save()
                }
            }
        }
        .preferredColorScheme(.dark)
        .task { _ = ensurePrefs(); _ = ensureProgress() }
    }

    @discardableResult
    private func ensurePrefs() -> BuddyPreferences {
        if let p = prefs.first { return p }
        let p = BuddyPreferences()
        context.insert(p)
        try? context.save()
        return p
    }

    @discardableResult
    private func ensureProgress() -> BuddyProgress {
        var descriptor = FetchDescriptor<BuddyProgress>()
        descriptor.fetchLimit = 1
        if let existing = try? context.fetch(descriptor).first { return existing }
        let p = BuddyProgress()
        context.insert(p)
        try? context.save()
        return p
    }
}

struct OnboardingView: View {
    var onContinue: () -> Void

    var body: some View {
        ZStack {
            BuddyTheme.field.ignoresSafeArea()
            VStack(spacing: 28) {
                Spacer()
                BuddyMark(size: 88, mood: .curious)
                VStack(spacing: 10) {
                    Text("Buddy")
                        .font(.system(size: 40, weight: .semibold, design: .rounded))
                        .tracking(-0.02)
                        .foregroundStyle(BuddyTheme.bone)
                    Text("What’s up, bud?")
                        .font(.title3)
                        .foregroundStyle(BuddyTheme.bone.opacity(0.9))
                    Text("Your marshmallow ghost for food energy.")
                        .font(.subheadline)
                        .foregroundStyle(BuddyTheme.dim)
                    Text("Watch what you eat.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(BuddyTheme.dim)
                }
                Text(DeviceAIReadiness.body)
                    .font(.subheadline)
                    .foregroundStyle(BuddyTheme.dim)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                Spacer()

                Button(action: onContinue) {
                    Text("Start watching")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(BuddyTheme.needle, in: RoundedRectangle(cornerRadius: BuddyTheme.radiusMD, style: .continuous))
                        .foregroundStyle(BuddyTheme.bone)
                }
                .buttonStyle(PressableButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 36)

                Text("Made by Night Folio")
                    .font(.caption2)
                    .foregroundStyle(BuddyTheme.dim.opacity(0.7))
                    .padding(.bottom, 12)
            }
        }
    }
}
