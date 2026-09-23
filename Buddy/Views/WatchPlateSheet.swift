import SwiftUI
import UIKit

struct WatchPlateSheet: View {
    let image: UIImage
    var caloriesSoFar: Int
    var target: Int
    var plateCount: Int
    var onConfirm: (PlateEntry) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var hint = ""
    @State private var phase: Phase = .analyzing
    @State private var estimate: MealWatchService.Estimate?
    @State private var errorText: String?
    @State private var editedCalories: Int = 0
    @State private var editedTitle: String = ""
    @FocusState private var hintFocused: Bool

    private enum Phase {
        case analyzing
        case ready
        case failed
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BuddyTheme.canvas.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 220)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: BuddyTheme.radiusLG, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: BuddyTheme.radiusLG, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                            }

                        buddyStatus

                        TextField("Optional hint (e.g. chicken rice)", text: $hint)
                            .textFieldStyle(.plain)
                            .padding(14)
                            .background(BuddyTheme.bone.opacity(0.08), in: RoundedRectangle(cornerRadius: BuddyTheme.radiusSM, style: .continuous))
                            .foregroundStyle(BuddyTheme.bone)
                            .focused($hintFocused)
                            .submitLabel(.done)
                            .onSubmit { Task { await analyze(force: true) } }

                        if phase == .ready, estimate != nil {
                            estimateCard
                            Button {
                                confirm()
                            } label: {
                                Text("Log plate · +\(15) XP")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(BuddyTheme.needle, in: RoundedRectangle(cornerRadius: BuddyTheme.radiusMD, style: .continuous))
                                    .foregroundStyle(BuddyTheme.bone)
                            }
                            .buttonStyle(PressableButtonStyle())
                        }

                        if phase == .failed {
                            Button {
                                Task { await analyze(force: true) }
                            } label: {
                                Text("Try again")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(BuddyTheme.bone.opacity(0.12), in: RoundedRectangle(cornerRadius: BuddyTheme.radiusMD, style: .continuous))
                                    .foregroundStyle(BuddyTheme.bone)
                            }
                            .buttonStyle(PressableButtonStyle())
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Watch plate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(BuddyTheme.dim)
                }
            }
            .task { await analyze(force: false) }
        }
        .preferredColorScheme(.dark)
    }

    private var buddyStatus: some View {
        HStack(alignment: .top, spacing: 12) {
            BuddyMark(size: 44, mood: phase == .ready ? .proud : .curious)
            VStack(alignment: .leading, spacing: 6) {
                switch phase {
                case .analyzing:
                    Text("Watching…")
                        .font(.headline)
                        .foregroundStyle(BuddyTheme.bone)
                    ProgressView()
                        .tint(BuddyTheme.needle)
                case .ready:
                    Text(estimate?.buddyLine ?? "")
                        .font(.body)
                        .foregroundStyle(BuddyTheme.bone)
                    if let e = estimate {
                        Text(e.usedFoundationModels ? "On-device estimate" : "Offline guess — edit if needed")
                            .font(.caption)
                            .foregroundStyle(BuddyTheme.dim)
                    }
                case .failed:
                    Text(errorText ?? "Couldn’t watch that plate.")
                        .font(.body)
                        .foregroundStyle(BuddyTheme.bone)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(BuddyTheme.bone.opacity(0.06), in: RoundedRectangle(cornerRadius: BuddyTheme.radiusMD, style: .continuous))
    }

    private var estimateCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Title", text: $editedTitle)
                .font(.title3.weight(.semibold))
                .foregroundStyle(BuddyTheme.bone)
            HStack {
                Text("kcal")
                    .foregroundStyle(BuddyTheme.dim)
                TextField("0", value: $editedCalories, format: .number)
                    .keyboardType(.numberPad)
                    .font(.title.monospacedDigit().weight(.semibold))
                    .foregroundStyle(BuddyTheme.bone)
            }
            if let e = estimate {
                Text(
                    String(
                        format: "P %.0fg · C %.0fg · F %.0fg · confidence %.0f%%",
                        e.proteinG, e.carbsG, e.fatG, e.confidence * 100
                    )
                )
                .font(.caption.monospacedDigit())
                .foregroundStyle(BuddyTheme.dim)
            }
        }
        .padding(16)
        .background(BuddyTheme.bone.opacity(0.06), in: RoundedRectangle(cornerRadius: BuddyTheme.radiusMD, style: .continuous))
    }

    private func analyze(force: Bool) async {
        phase = .analyzing
        errorText = nil
        let day = MealWatchBeat.DayContext(
            caloriesSoFar: caloriesSoFar,
            target: target,
            plateCount: plateCount,
            userHint: hint
        )
        do {
            let description = try await PlateVisionService.describe(image)
            let result = await MealWatchService.estimate(plateDescription: description, day: day)
            estimate = result
            editedTitle = result.title
            editedCalories = result.calories
            phase = .ready
        } catch {
            if force {
                let result = await MealWatchService.estimate(plateDescription: "", day: day)
                estimate = result
                editedTitle = result.title
                editedCalories = result.calories
                phase = .ready
            } else {
                errorText = error.localizedDescription
                phase = .failed
            }
        }
    }

    private func confirm() {
        guard let estimate else { return }
        let jpeg = image.jpegData(compressionQuality: 0.72)
        let entry = PlateEntry(
            title: editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? estimate.title : editedTitle,
            calories: max(0, editedCalories),
            proteinG: estimate.proteinG,
            carbsG: estimate.carbsG,
            fatG: estimate.fatG,
            confidence: estimate.confidence,
            buddyLine: estimate.buddyLine,
            notes: hint,
            photoData: jpeg
        )
        onConfirm(entry)
    }
}
