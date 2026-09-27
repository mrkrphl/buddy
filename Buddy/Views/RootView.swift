import SwiftData
import SwiftUI
import UIKit

struct RootView: View {
    @Query private var prefs: [BuddyPreferences]
    @Environment(\.modelContext) private var context
    @State private var onboardingStep: OnboardingStep = .welcome

    var body: some View {
        Group {
            if let p = prefs.first, p.hasSeenOnboarding {
                MainTabView()
            } else {
                OnboardingFlowView(step: $onboardingStep) {
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

// MARK: - Onboarding

enum OnboardingStep: Int, Hashable {
    case welcome
    case kitchen
}

struct OnboardingFlowView: View {
    @Binding var step: OnboardingStep
    var onComplete: () -> Void

    var body: some View {
        ZStack {
            BuddyTheme.field.ignoresSafeArea()
            switch step {
            case .welcome:
                OnboardingWelcomeView {
                    step = .kitchen
                }
            case .kitchen:
                KitchenEditorScreen(
                    mode: .onboarding,
                    onFinished: onComplete,
                    onSkip: onComplete
                )
            }
        }
    }
}

struct OnboardingWelcomeView: View {
    var onContinue: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appear = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            BuddyMark(
                size: 120,
                mood: .curious,
                reflection: .neutral,
                showsCarrot: false,
                animated: true,
                softCloth: false
            )
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 10)
            .accessibilityLabel("Buddy")

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
                Text("See what you eat.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(BuddyTheme.dim)
            }
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 8)

            Text(DeviceAIReadiness.body)
                .font(.subheadline)
                .foregroundStyle(BuddyTheme.dim)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .opacity(appear ? 1 : 0)

            Spacer()

            Button(action: onContinue) {
                Text("Set up kitchen")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(BuddyTheme.needle, in: RoundedRectangle(cornerRadius: BuddyTheme.radiusMD, style: .continuous))
                    .foregroundStyle(BuddyTheme.bone)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 36)

            Text("Mark Raphael Sto. Domingo")
                .font(.caption2)
                .foregroundStyle(BuddyTheme.dim.opacity(0.7))
                .padding(.bottom, 12)
        }
        .onAppear {
            guard !reduceMotion else { appear = true; return }
            withAnimation(.easeOut(duration: 0.35).delay(0.04)) { appear = true }
        }
    }
}
