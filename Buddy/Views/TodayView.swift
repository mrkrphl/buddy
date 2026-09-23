import SwiftData
import SwiftUI
import UIKit

struct TodayView: View {
    @Query(sort: \PlateEntry.createdAt, order: .reverse) private var plates: [PlateEntry]
    @Query private var progressRows: [BuddyProgress]
    @Query private var prefsRows: [BuddyPreferences]
    @Environment(\.modelContext) private var context

    @State private var showWatchFlow = false
    @State private var showSettings = false
    @State private var pendingImage: UIImage?

    private var progress: BuddyProgress? { progressRows.first }
    private var prefs: BuddyPreferences? { prefsRows.first }

    private var todayPlates: [PlateEntry] {
        let key = DayKey.make()
        return plates.filter { DayKey.make($0.createdAt) == key }
    }

    private var caloriesToday: Int {
        todayPlates.reduce(0) { $0 + $1.calories }
    }

    private var target: Int { prefs?.dailyCalorieTarget ?? 2200 }

    var body: some View {
        NavigationStack {
            ZStack {
                BuddyTheme.field.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        header
                        energyRing
                        PlatePhotoCapture { image in
                            pendingImage = image
                            showWatchFlow = true
                        }
                        plateFeed
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(BuddyTheme.dim)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
            .sheet(isPresented: $showWatchFlow) {
                if let image = pendingImage {
                    WatchPlateSheet(
                        image: image,
                        caloriesSoFar: caloriesToday,
                        target: target,
                        plateCount: todayPlates.count
                    ) { entry in
                        context.insert(entry)
                        progress?.awardWatch(on: DayKey.make(), xpGain: 15)
                        try? context.save()
                        showWatchFlow = false
                        pendingImage = nil
                    }
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 16) {
            BuddyMark(size: 64, mood: progress?.mood ?? .curious)
            VStack(alignment: .leading, spacing: 6) {
                Text("Buddy")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .tracking(-0.02)
                    .foregroundStyle(BuddyTheme.bone)
                Text(progress?.mood.label ?? "Curious")
                    .font(.subheadline)
                    .foregroundStyle(BuddyTheme.dim)
                HStack(spacing: 12) {
                    Label("Lv \(progress?.level ?? 1)", systemImage: "star.fill")
                    Label("\(progress?.streakDays ?? 0)d", systemImage: "flame.fill")
                    Label("\(progress?.xp ?? 0) XP", systemImage: "bolt.fill")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(BuddyTheme.needle)
                .symbolRenderingMode(.hierarchical)
            }
            Spacer(minLength: 0)
        }
    }

    private var plateCountLabel: String {
        let n = todayPlates.count
        return n == 1 ? "1 plate watched" : "\(n) plates watched"
    }

    private var energyRing: some View {
        let ratio = target > 0 ? min(1.2, Double(caloriesToday) / Double(target)) : 0
        return VStack(alignment: .leading, spacing: 12) {
            Text("Today")
                .font(.headline)
                .foregroundStyle(BuddyTheme.bone)
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(BuddyTheme.bone.opacity(0.12), lineWidth: 10)
                    Circle()
                        .trim(from: 0, to: min(1, ratio))
                        .stroke(
                            ratio > 1 ? BuddyTheme.needle : BuddyTheme.bone,
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.4, dampingFraction: 1.0), value: caloriesToday)
                    VStack(spacing: 2) {
                        Text("\(caloriesToday)")
                            .font(.system(size: 22, weight: .semibold, design: .rounded).monospacedDigit())
                            .foregroundStyle(BuddyTheme.bone)
                        Text("/ \(target)")
                            .font(.caption)
                            .foregroundStyle(BuddyTheme.dim)
                    }
                }
                .frame(width: 100, height: 100)

                VStack(alignment: .leading, spacing: 8) {
                    Text(plateCountLabel)
                        .font(.subheadline)
                        .foregroundStyle(BuddyTheme.bone)
                    Text(DeviceAIReadiness.headline)
                        .font(.caption)
                        .foregroundStyle(BuddyTheme.dim)
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .background(BuddyTheme.bone.opacity(0.06), in: RoundedRectangle(cornerRadius: BuddyTheme.radiusLG, style: .continuous))
        }
    }

    private var plateFeed: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Plates")
                .font(.headline)
                .foregroundStyle(BuddyTheme.bone)

            if todayPlates.isEmpty {
                Text("Snap a plate — Buddy watches with you.")
                    .font(.subheadline)
                    .foregroundStyle(BuddyTheme.dim)
                    .padding(.vertical, 20)
            } else {
                ForEach(todayPlates, id: \.id) { plate in
                    PlateRow(plate: plate)
                }
            }
        }
    }
}

struct PlateRow: View {
    let plate: PlateEntry

    var body: some View {
        HStack(spacing: 14) {
            plateThumb
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: BuddyTheme.radiusSM, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: BuddyTheme.radiusSM, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(plate.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(BuddyTheme.bone)
                Text("\(plate.calories) kcal")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(BuddyTheme.dim)
                if !plate.buddyLine.isEmpty {
                    Text(plate.buddyLine)
                        .font(.caption)
                        .foregroundStyle(BuddyTheme.dim)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(BuddyTheme.bone.opacity(0.05), in: RoundedRectangle(cornerRadius: BuddyTheme.radiusMD, style: .continuous))
    }

    @ViewBuilder
    private var plateThumb: some View {
        if let data = plate.photoData, let ui = UIImage(data: data) {
            Image(uiImage: ui)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                BuddyTheme.bone.opacity(0.1)
                Image(systemName: "fork.knife")
                    .foregroundStyle(BuddyTheme.dim)
            }
        }
    }
}
