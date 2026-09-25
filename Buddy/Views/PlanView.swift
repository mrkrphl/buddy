import SwiftData
import SwiftUI

struct PlanView: View {
    @Query(sort: \PlannedMeal.createdAt, order: .forward) private var allPlans: [PlannedMeal]
    @Query(sort: \PlateEntry.createdAt, order: .reverse) private var plates: [PlateEntry]
    @Query private var prefsRows: [BuddyPreferences]
    @Query private var progressRows: [BuddyProgress]
    @Environment(\.modelContext) private var context

    @State private var showAdd = false
    @State private var draftTitle = ""
    @State private var draftSlot: MealSlot = .lunch
    @State private var draftCalories = 500

    private var prefs: BuddyPreferences? { prefsRows.first }
    private var progress: BuddyProgress? { progressRows.first }
    private var target: Int { prefs?.dailyCalorieTarget ?? 2200 }
    private var todayKey: String { DayKey.make() }

    private var todayPlans: [PlannedMeal] {
        allPlans.filter { $0.dayKey == todayKey }
    }

    private var plannedTotal: Int {
        todayPlans.reduce(0) { $0 + $1.plannedCalories }
    }

    private var reflection: BuddyReflection {
        BuddyReflection.compute(
            plates: plates.map(PlateSnapshot.init(from:)),
            dailyTarget: target
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BuddyTheme.field.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        intro
                        planSummary
                        planList
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Plan & Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(BuddyTheme.needle)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
            .sheet(isPresented: $showAdd) {
                addSheet
            }
        }
    }

    private var intro: some View {
        HStack(alignment: .center, spacing: 14) {
            BuddyMark(
                size: 48,
                mood: progress?.mood ?? .curious,
                reflection: reflection,
                animated: true
            )
            VStack(alignment: .leading, spacing: 6) {
                Text("Plan first. Log when it’s real.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(BuddyTheme.bone)
                Text(reflection.blurb)
                    .font(.caption)
                    .foregroundStyle(BuddyTheme.dim)
            }
            Spacer(minLength: 0)
        }
    }

    private var planSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today’s plan")
                .font(.headline)
                .foregroundStyle(BuddyTheme.bone)
            HStack {
                Text("\(plannedTotal) kcal planned")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(BuddyTheme.dim)
                Spacer()
                Text("Target \(target)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(BuddyTheme.dim)
            }
            ProgressView(value: Double(min(plannedTotal, target)), total: Double(max(target, 1)))
                .tint(BuddyTheme.needle)
        }
        .padding(16)
        .background(BuddyTheme.bone.opacity(0.06), in: RoundedRectangle(cornerRadius: BuddyTheme.radiusLG, style: .continuous))
    }

    private var planList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Meals")
                .font(.headline)
                .foregroundStyle(BuddyTheme.bone)

            if todayPlans.isEmpty {
                Text("Add breakfast, lunch, dinner — then snap when you eat.")
                    .font(.subheadline)
                    .foregroundStyle(BuddyTheme.dim)
                    .padding(.vertical, 16)
            } else {
                ForEach(todayPlans, id: \.id) { meal in
                    planRow(meal)
                }
            }
        }
    }

    private func planRow(_ meal: PlannedMeal) -> some View {
        HStack(spacing: 12) {
            Button {
                meal.isLogged.toggle()
                try? context.save()
            } label: {
                Image(systemName: meal.isLogged ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(meal.isLogged ? BuddyTheme.needle : BuddyTheme.dim)
            }
            .buttonStyle(PressableButtonStyle())

            VStack(alignment: .leading, spacing: 4) {
                Text(meal.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(meal.isLogged ? BuddyTheme.dim : BuddyTheme.bone)
                    .strikethrough(meal.isLogged)
                Text("\(meal.slot.label) · \(meal.plannedCalories) kcal")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(BuddyTheme.dim)
            }
            Spacer(minLength: 0)

            Button(role: .destructive) {
                context.delete(meal)
                try? context.save()
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(BuddyTheme.dim.opacity(0.7))
            }
            .buttonStyle(PressableButtonStyle())
        }
        .padding(14)
        .background(BuddyTheme.bone.opacity(0.05), in: RoundedRectangle(cornerRadius: BuddyTheme.radiusMD, style: .continuous))
    }

    private var addSheet: some View {
        NavigationStack {
            ZStack {
                BuddyTheme.field.ignoresSafeArea()
                Form {
                    Section("What are you planning?") {
                        TextField("e.g. Chicken rice bowl", text: $draftTitle)
                        Picker("Slot", selection: $draftSlot) {
                            ForEach(MealSlot.allCases) { slot in
                                Text(slot.label).tag(slot)
                            }
                        }
                        Stepper("\(draftCalories) kcal", value: $draftCalories, in: 50...2000, step: 25)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Add plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAdd = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { savePlan() }
                        .disabled(draftTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.medium])
    }

    private func savePlan() {
        let title = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        let meal = PlannedMeal(
            dayKey: todayKey,
            slot: draftSlot,
            title: title,
            plannedCalories: draftCalories
        )
        context.insert(meal)
        try? context.save()
        draftTitle = ""
        draftCalories = 500
        showAdd = false
    }
}
