import SwiftUI

/// Night kitchen counter diorama — mockup-faithful scene with lit/dim appliance sprites.
struct KitchenCounterView: View {
    enum Mode {
        case onboarding
        case editing
    }

    var mode: Mode = .editing
    var owned: Binding<Set<KitchenApplianceID>>
    var notes: Binding<[String: String]>
    var onFinished: () -> Void
    var onSkip: (() -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var detailID: KitchenApplianceID?
    @State private var showAddShelf = false
    @State private var appear = false
    @State private var buddyPeeked = false

    private var counterItems: [KitchenApplianceID] {
        KitchenApplianceID.counterDefaults
    }

    private var readyCount: Int { owned.wrappedValue.count }

    var body: some View {
        ZStack {
            BuddyTheme.field.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                Spacer(minLength: 8)

                VStack(spacing: 10) {
                    kitchenScene
                        .padding(.horizontal, 16)

                    applianceLabels
                        .padding(.horizontal, 22)
                }
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 14)

                statusLine
                    .padding(.top, 14)
                    .animation(BuddyTheme.easeOut, value: readyCount)

                Spacer(minLength: 12)

                footer
                    .padding(.horizontal, 24)
                    .padding(.bottom, mode == .onboarding ? 28 : 16)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            guard !reduceMotion else {
                appear = true
                buddyPeeked = true
                return
            }
            withAnimation(.easeOut(duration: 0.35).delay(0.04)) { appear = true }
            withAnimation(.timingCurve(0.2, 0, 0, 1, duration: 0.4).delay(0.16)) {
                buddyPeeked = true
            }
        }
        .sheet(item: $detailID) { id in
            KitchenApplianceDetailSheet(
                appliance: id,
                isOwned: Binding(
                    get: { owned.wrappedValue.contains(id) },
                    set: { on in toggle(id, on: on) }
                ),
                note: Binding(
                    get: { notes.wrappedValue[id.rawValue] ?? "" },
                    set: { notes.wrappedValue[id.rawValue] = $0 }
                )
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showAddShelf) {
            AddApplianceShelfView(owned: owned)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(mode == .onboarding ? "Stock Buddy’s kitchen" : "Your kitchen")
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundStyle(BuddyTheme.bone)
            Text(mode == .onboarding
                 ? "Tap what you cook with — we’ll keep suggestions honest."
                 : "What can Buddy cook with?")
                .font(.subheadline)
                .foregroundStyle(BuddyTheme.dim)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statusLine: some View {
        Text(readyCount == 0
             ? "Tap an appliance to plug it in"
             : "\(readyCount) appliance\(readyCount == 1 ? "" : "s") ready")
            .font(.subheadline.weight(.medium))
            .foregroundStyle(BuddyTheme.dim)
    }

    /// Empty-cabinet plate + Buddy sneaking from behind left cabinets + sprites on the wood rail.
    private var kitchenScene: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let buddySize = min(64, w * 0.18)
            ZStack(alignment: .topLeading) {
                Image("KitchenBackdrop")
                    .resizable()
                    .scaledToFill()
                    .frame(width: w, height: h)
                    .clipped()
                    .allowsHitTesting(false)

                // Face in the dark gap; right side slides behind the left cabinet.
                BuddyMark(
                    size: buddySize,
                    mood: .curious,
                    reflection: .neutral,
                    showsCarrot: false,
                    animated: true,
                    softCloth: false
                )
                .padding(.leading, w * 0.08)
                .padding(.top, h * 0.06)
                .offset(x: buddyPeeked ? 0 : -buddySize * 0.35)
                .opacity(buddyPeeked ? 1 : 0)
                .allowsHitTesting(false)
                .accessibilityHidden(true)

                // Cabinet, counter, and oven redrawn over him — void stays clear.
                Image("KitchenOccluder")
                    .resizable()
                    .scaledToFill()
                    .frame(width: w, height: h)
                    .clipped()
                    .allowsHitTesting(false)

                // Feet on the wood top. Inset lives inside the scene frame.
                HStack(alignment: .bottom, spacing: w * 0.006) {
                    ForEach(counterItems) { id in
                        KitchenApplianceSpriteButton(
                            appliance: id,
                            isOn: owned.wrappedValue.contains(id),
                            showsChrome: false,
                            onTap: { toggle(id) },
                            onInfo: { detailID = id }
                        )
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, w * 0.05)
                // Wood top is y 0.82–0.87 of the backdrop. Feet sit on the front of that band.
                .padding(.bottom, h * 0.125)
                .frame(width: w, height: h, alignment: .bottom)
            }
            .clipShape(RoundedRectangle(cornerRadius: BuddyTheme.radiusLG, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: BuddyTheme.radiusLG, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
            }
        }
        .aspectRatio(4 / 3, contentMode: .fit)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Kitchen counter")
    }

    /// Labels + needle sparks under the plate.
    private var applianceLabels: some View {
        HStack(alignment: .top, spacing: 4) {
            ForEach(counterItems) { id in
                let isOn = owned.wrappedValue.contains(id)
                Button {
                    toggle(id)
                } label: {
                    VStack(spacing: 5) {
                        Circle()
                            .fill(BuddyTheme.needle)
                            .frame(width: 6, height: 6)
                            .scaleEffect(isOn ? 1 : 0.6)
                            .opacity(isOn ? 1 : 0)
                            .shadow(color: isOn ? BuddyTheme.needle.opacity(0.55) : .clear, radius: 4)
                            .animation(BuddyTheme.easeOut, value: isOn)
                        Text(id.title)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(isOn ? BuddyTheme.bone : BuddyTheme.dim.opacity(0.85))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityLabel(id.title)
                .accessibilityValue(isOn ? "In your kitchen" : "Not added")
                .accessibilityHint("Double tap to toggle")
                .contextMenu {
                    Button(isOn ? "Remove from kitchen" : "Add to kitchen") { toggle(id) }
                    Button("Notes…") { detailID = id }
                }
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 12) {
            if mode == .editing {
                HStack(spacing: 12) {
                    Button { showAddShelf = true } label: {
                        Text("Edit")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: BuddyTheme.radiusMD, style: .continuous)
                                    .strokeBorder(BuddyTheme.bone.opacity(0.22), lineWidth: 1)
                            )
                            .foregroundStyle(BuddyTheme.bone)
                    }
                    .buttonStyle(PressableButtonStyle())

                    Button(action: onFinished) {
                        Text("Done")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(BuddyTheme.needle, in: RoundedRectangle(cornerRadius: BuddyTheme.radiusMD, style: .continuous))
                            .foregroundStyle(BuddyTheme.bone)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            } else {
                Button { showAddShelf = true } label: {
                    Text(readyCount == 0 ? "Add appliances" : "Add more")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(BuddyTheme.bone)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: BuddyTheme.radiusMD, style: .continuous)
                                .strokeBorder(BuddyTheme.bone.opacity(0.18), lineWidth: 1)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button(action: onFinished) {
                    Text("Save kitchen")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(BuddyTheme.needle, in: RoundedRectangle(cornerRadius: BuddyTheme.radiusMD, style: .continuous))
                        .foregroundStyle(BuddyTheme.bone)
                }
                .buttonStyle(PressableButtonStyle())

                if let onSkip {
                    Button("I’ll do this later", action: onSkip)
                        .font(.subheadline)
                        .foregroundStyle(BuddyTheme.dim)
                        .padding(.top, 2)
                }
            }
        }
    }

    private func toggle(_ id: KitchenApplianceID, on: Bool? = nil) {
        var next = owned.wrappedValue
        let shouldOwn = on ?? !next.contains(id)
        if shouldOwn {
            next.insert(id)
        } else {
            next.remove(id)
        }
        withAnimation(BuddyTheme.easeOut) {
            owned.wrappedValue = next
        }
    }
}

// MARK: - Sprite button

private struct KitchenApplianceSpriteButton: View {
    let appliance: KitchenApplianceID
    let isOn: Bool
    var showsChrome: Bool = true
    let onTap: () -> Void
    let onInfo: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                spriteStack
                    .frame(height: showsChrome ? 88 : 76, alignment: .bottom)
                    .background(alignment: .bottom) {
                        Ellipse()
                            .fill(Color.black.opacity(0.55))
                            .frame(height: 5)
                            .padding(.horizontal, 10)
                            .blur(radius: 1.5)
                            .offset(y: 1)
                    }
                    .scaleEffect(isOn ? 1.0 : 0.96, anchor: .bottom)
                    .opacity(isOn ? 1 : 0.9)
                    .animation(BuddyTheme.easeOut, value: isOn)

                if showsChrome {
                    Circle()
                        .fill(BuddyTheme.needle)
                        .frame(width: 6, height: 6)
                        .opacity(isOn ? 1 : 0)
                    Text(appliance.title)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(isOn ? BuddyTheme.bone : BuddyTheme.dim.opacity(0.85))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(appliance.title)
        .accessibilityValue(isOn ? "In your kitchen" : "Not added")
        .accessibilityHint("Double tap to toggle")
        .accessibilityAction(named: "Notes") { onInfo() }
        .contextMenu {
            Button(isOn ? "Remove from kitchen" : "Add to kitchen", action: onTap)
            Button("Notes…", action: onInfo)
        }
    }

    @ViewBuilder
    private var spriteStack: some View {
        ZStack(alignment: .bottom) {
            if let off = appliance.offAsset, let on = appliance.onAsset {
                Image(off)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .opacity(isOn ? 0 : 1)
                    .accessibilityHidden(true)
                    .allowsHitTesting(false)
                Image(on)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .opacity(isOn ? 1 : 0)
                    .accessibilityHidden(true)
                    .allowsHitTesting(false)
            } else {
                Image(systemName: appliance.systemImage)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(isOn ? BuddyTheme.bone : BuddyTheme.dim)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
        }
    }
}
