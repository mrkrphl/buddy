import SwiftData
import SwiftUI

struct SettingsView: View {
    @Query private var prefsRows: [BuddyPreferences]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    private var prefs: BuddyPreferences? { prefsRows.first }

    var body: some View {
        NavigationStack {
            ZStack {
                BuddyTheme.field.ignoresSafeArea()
                Form {
                    Section("Daily energy") {
                        Stepper(
                            value: Binding(
                                get: { prefs?.dailyCalorieTarget ?? 2200 },
                                set: { newValue in
                                    prefs?.dailyCalorieTarget = newValue
                                    try? context.save()
                                }
                            ),
                            in: 1200...4500,
                            step: 50
                        ) {
                            Text("\(prefs?.dailyCalorieTarget ?? 2200) kcal")
                                .monospacedDigit()
                        }
                    }

                    Section("On-device Buddy") {
                        Text(DeviceAIReadiness.headline)
                            .foregroundStyle(BuddyTheme.bone)
                        Text(DeviceAIReadiness.body)
                            .font(.footnote)
                            .foregroundStyle(BuddyTheme.dim)
                    }

                    Section("Studio") {
                        Text("Made by Night Folio")
                            .foregroundStyle(BuddyTheme.dim)
                        Text("Rooms, not résumés.")
                            .font(.footnote)
                            .foregroundStyle(BuddyTheme.dim)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
