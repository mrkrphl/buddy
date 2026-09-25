import SwiftUI

/// Pantry-shelf browser for appliances beyond the main counter row.
struct AddApplianceShelfView: View {
    @Binding var owned: Set<KitchenApplianceID>
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var filtered: [KitchenApplianceID] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let all = KitchenApplianceID.allCases
        guard !q.isEmpty else { return all }
        return all.filter {
            $0.title.lowercased().contains(q) || $0.blurb.lowercased().contains(q)
        }
    }

    private var selectedCount: Int { owned.count }

    var body: some View {
        NavigationStack {
            ZStack {
                BuddyTheme.field.ignoresSafeArea()
                VStack(spacing: 0) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(BuddyTheme.dim)
                        TextField("Search appliances", text: $query)
                            .foregroundStyle(BuddyTheme.bone)
                            .autocorrectionDisabled()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: BuddyTheme.radiusSM, style: .continuous)
                            .fill(BuddyTheme.canvas)
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 16)

                    ScrollView {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ],
                            spacing: 16
                        ) {
                            ForEach(filtered) { id in
                                shelfCell(id)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }

                    VStack(spacing: 0) {
                        Divider().overlay(BuddyTheme.bone.opacity(0.08))
                        Button {
                            dismiss()
                        } label: {
                            Text(selectedCount == 0 ? "Done" : "Add selected · \(selectedCount)")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(BuddyTheme.needle, in: RoundedRectangle(cornerRadius: BuddyTheme.radiusMD, style: .continuous))
                                .foregroundStyle(BuddyTheme.bone)
                        }
                        .buttonStyle(PressableButtonStyle())
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                    }
                    .background(BuddyTheme.field)
                }
            }
            .navigationTitle("Add appliance")
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

    private func shelfCell(_ id: KitchenApplianceID) -> some View {
        let on = owned.contains(id)
        return Button {
            withAnimation(BuddyTheme.easeOut) {
                if on { owned.remove(id) } else { owned.insert(id) }
            }
        } label: {
            VStack(spacing: 10) {
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: BuddyTheme.radiusSM, style: .continuous)
                        .fill(BuddyTheme.canvas)
                        .frame(height: 84)
                        .overlay {
                            RoundedRectangle(cornerRadius: BuddyTheme.radiusSM, style: .continuous)
                                .strokeBorder(
                                    on ? BuddyTheme.needle.opacity(0.55) : BuddyTheme.bone.opacity(0.08),
                                    lineWidth: 1
                                )
                        }

                    Group {
                        if let off = id.offAsset, let onName = id.onAsset {
                            Image(on ? onName : off)
                                .resizable()
                                .interpolation(.high)
                                .scaledToFit()
                                .padding(10)
                                .frame(height: 72)
                        } else {
                            Image(systemName: id.systemImage)
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundStyle(on ? BuddyTheme.bone : BuddyTheme.dim)
                                .frame(height: 72)
                        }
                    }
                    .offset(y: -4)

                    Circle()
                        .fill(BuddyTheme.needle)
                        .frame(width: 5, height: 5)
                        .opacity(on ? 1 : 0)
                        .offset(y: 32)
                        .shadow(color: on ? BuddyTheme.needle.opacity(0.5) : .clear, radius: 3)
                }
                Text(id.title)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(on ? BuddyTheme.bone : BuddyTheme.dim)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(id.title)
        .accessibilityValue(on ? "Selected" : "Not selected")
    }
}
