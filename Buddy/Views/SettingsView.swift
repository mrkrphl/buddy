import SwiftData
import SwiftUI

struct SettingsView: View {
    @Query private var prefsRows: [BuddyPreferences]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    private var prefs: BuddyPreferences? { prefsRows.first }

    private var kitchenSummary: String {
        let n = prefs?.ownedAppliances.count ?? 0
        if n == 0 { return "Not stocked yet" }
        return "\(n) appliance\(n == 1 ? "" : "s")"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BuddyTheme.field.ignoresSafeArea()
                Form {
                    Section("Your kitchen") {
                        NavigationLink {
                            KitchenEditorScreen(mode: .editing)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Appliances")
                                        .foregroundStyle(BuddyTheme.bone)
                                    Text(kitchenSummary)
                                        .font(.footnote)
                                        .foregroundStyle(BuddyTheme.dim)
                                }
                                Spacer()
                            }
                        }
                    }

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
