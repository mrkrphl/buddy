import SwiftUI

struct KitchenApplianceDetailSheet: View {
    let appliance: KitchenApplianceID
    @Binding var isOwned: Bool
    @Binding var note: String
    @Environment(\.dismiss) private var dismiss
    @FocusState private var noteFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                BuddyTheme.field.ignoresSafeArea()
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(BuddyTheme.bone.opacity(0.08))
                            .frame(width: 108, height: 108)
                        if let on = appliance.onAsset, let off = appliance.offAsset {
                            Image(isOwned ? on : off)
                                .resizable()
                                .interpolation(.high)
                                .scaledToFit()
                                .padding(14)
                                .frame(width: 100, height: 100)
                        } else {
                            Image(systemName: appliance.systemImage)
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundStyle(BuddyTheme.bone)
                        }
                    }
                    .padding(.top, 8)

                    VStack(spacing: 8) {
                        Text(appliance.title)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(BuddyTheme.bone)
                        Text(appliance.blurb)
                            .font(.subheadline)
                            .foregroundStyle(BuddyTheme.dim)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }

                    Toggle(isOn: $isOwned) {
                        Text("In your kitchen")
                            .foregroundStyle(BuddyTheme.bone)
                    }
                    .tint(BuddyTheme.needle)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(
                        RoundedRectangle(cornerRadius: BuddyTheme.radiusMD, style: .continuous)
                            .fill(BuddyTheme.canvas)
                    )

                    TextField("Any notes…", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                        .focused($noteFocused)
                        .padding(14)
                        .foregroundStyle(BuddyTheme.bone)
                        .background(
                            RoundedRectangle(cornerRadius: BuddyTheme.radiusMD, style: .continuous)
                                .fill(BuddyTheme.canvas)
                        )

                    Spacer(minLength: 0)

                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(BuddyTheme.needle, in: RoundedRectangle(cornerRadius: BuddyTheme.radiusMD, style: .continuous))
                            .foregroundStyle(BuddyTheme.bone)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
                .padding(24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(BuddyTheme.dim)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
