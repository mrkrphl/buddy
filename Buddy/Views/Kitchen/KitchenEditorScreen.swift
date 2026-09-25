import SwiftData
import SwiftUI

/// Bridges SwiftData prefs ↔ kitchen editor bindings.
struct KitchenEditorScreen: View {
    var mode: KitchenCounterView.Mode = .editing
    var onFinished: (() -> Void)? = nil
    var onSkip: (() -> Void)? = nil

    @Query private var prefsRows: [BuddyPreferences]
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var owned: Set<KitchenApplianceID> = []
    @State private var notes: [String: String] = [:]
    @State private var didLoad = false

    private var prefs: BuddyPreferences? { prefsRows.first }

    var body: some View {
        KitchenCounterView(
            mode: mode,
            owned: $owned,
            notes: $notes,
            onFinished: {
                persist()
                if let onFinished {
                    onFinished()
                } else {
                    dismiss()
                }
            },
            onSkip: onSkip.map { skip in
                {
                    persist()
                    skip()
                }
            }
        )
        .onAppear(perform: loadIfNeeded)
        .onChange(of: owned) { _, _ in persistQuietly() }
        .onChange(of: notes) { _, _ in persistQuietly() }
    }

    private func loadIfNeeded() {
        guard !didLoad else { return }
        didLoad = true
        if let prefs {
            owned = prefs.ownedAppliances
            notes = prefs.applianceNotes
        }
    }

    private func persist() {
        guard let prefs else { return }
        prefs.ownedAppliances = owned
        // Clean empty notes
        var cleaned = notes
        for (k, v) in cleaned where v.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            cleaned.removeValue(forKey: k)
        }
        notes = cleaned
        prefs.applianceNotes = cleaned
        try? context.save()
    }

    private func persistQuietly() {
        guard didLoad else { return }
        persist()
    }
}
