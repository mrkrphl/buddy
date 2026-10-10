import SwiftData
import SwiftUI

struct ChatView: View {
    @Query(sort: \PlateEntry.createdAt, order: .reverse) private var plates: [PlateEntry]
    @Query(sort: \ChatMessage.createdAt, order: .forward) private var messages: [ChatMessage]
    @Query(sort: \PlannedMeal.createdAt, order: .forward) private var plans: [PlannedMeal]
    @Query private var prefsRows: [BuddyPreferences]
    @Query private var progressRows: [BuddyProgress]
    @Environment(\.modelContext) private var context
    @Environment(\.buddyRouter) private var router

    @State private var draft = ""
    @State private var isThinking = false
    @State private var pending: PendingConfirm?
    @FocusState private var focused: Bool

    private enum PendingConfirm: Equatable {
        case goal(kcal: Int)
        case logPlate
    }

    private var prefs: BuddyPreferences? { prefsRows.first }
    private var progress: BuddyProgress? { progressRows.first }
    private var target: Int { prefs?.dailyCalorieTarget ?? 2200 }

    private var todayPlates: [PlateEntry] {
        let key = DayKey.make()
        return plates.filter { DayKey.make($0.createdAt) == key }
    }

    private var caloriesToday: Int {
        todayPlates.reduce(0) { $0 + $1.calories }
    }

    private var reflection: BuddyReflection {
        BuddyReflection.compute(
            plates: plates.map(PlateSnapshot.init(from:)),
            dailyTarget: target
        )
    }

    private var talkContext: BuddyTalkBeat.Context {
        let todayKey = DayKey.make()
        let titles = plans.filter { $0.dayKey == todayKey && !$0.isLogged }.map(\.title)
        return BuddyTalkBeat.Context(
            caloriesToday: caloriesToday,
            target: target,
            plateCount: todayPlates.count,
            reflection: reflection,
            plannedTitles: titles
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BuddyTheme.field.ignoresSafeArea()
                VStack(spacing: 0) {
                    buddyBanner
                    Divider().overlay(BuddyTheme.bone.opacity(0.08))
                    messageList
                    if let pending {
                        confirmBar(pending)
                    }
                    composer
                }
            }
            .navigationTitle("Buddy")
            .navigationBarTitleDisplayMode(.inline)
            .task { seedOpeningIfNeeded() }
        }
    }

    private var buddyBanner: some View {
        HStack(spacing: 14) {
            BuddyMark(
                size: 48,
                mood: progress?.mood ?? .curious,
                reflection: reflection,
                animated: true
            )
            VStack(alignment: .leading, spacing: 4) {
                Text(reflection.label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(BuddyTheme.bone)
                Text(reflection.blurb)
                    .font(.caption)
                    .foregroundStyle(BuddyTheme.dim)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .animation(BuddyTheme.morph, value: reflection)
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(messages, id: \.id) { msg in
                        bubble(msg)
                            .id(msg.id)
                    }
                    if isThinking {
                        HStack(spacing: 8) {
                            ProgressView()
                                .tint(BuddyTheme.needle)
                            Text("Buddy’s thinking…")
                                .font(.caption)
                                .foregroundStyle(BuddyTheme.dim)
                        }
                        .padding(.horizontal, 4)
                        .id("thinking")
                    }
                }
                .padding(16)
            }
            .onChange(of: messages.count) { _, _ in
                scrollToEnd(proxy)
            }
            .onChange(of: isThinking) { _, thinking in
                if thinking { scrollToEnd(proxy) }
            }
        }
    }

    private func bubble(_ msg: ChatMessage) -> some View {
        HStack {
            if msg.isUser { Spacer(minLength: 40) }
            Text(msg.text)
                .font(.body)
                .foregroundStyle(msg.isUser ? BuddyTheme.bone : BuddyTheme.field)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    msg.isUser
                        ? BuddyTheme.bone.opacity(0.12)
                        : BuddyTheme.bone,
                    in: RoundedRectangle(cornerRadius: BuddyTheme.radiusMD, style: .continuous)
                )
            if !msg.isUser { Spacer(minLength: 40) }
        }
    }

    private func confirmBar(_ pending: PendingConfirm) -> some View {
        let confirmTitle: String
        switch pending {
        case .goal(let kcal):
            confirmTitle = "Set to \(BuddyTalkBeat.formatKcal(kcal))"
        case .logPlate:
            confirmTitle = "Log plate"
        }
        return HStack(spacing: 10) {
            Button {
                dismissPending(announce: true)
            } label: {
                Text("Not now")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(BuddyTheme.bone)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(BuddyTheme.bone.opacity(0.1), in: RoundedRectangle(cornerRadius: BuddyTheme.radiusSM, style: .continuous))
            }
            .buttonStyle(PressableButtonStyle())

            Button {
                confirmPending()
            } label: {
                Text(confirmTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(BuddyTheme.field)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(BuddyTheme.needle, in: RoundedRectangle(cornerRadius: BuddyTheme.radiusSM, style: .continuous))
            }
            .buttonStyle(PressableButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(BuddyTheme.canvas.opacity(0.98))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var composer: some View {
        HStack(spacing: 10) {
            TextField("Ask Buddy…", text: $draft, axis: .vertical)
                .lineLimit(1...4)
                .focused($focused)
                .padding(12)
                .background(BuddyTheme.bone.opacity(0.08), in: RoundedRectangle(cornerRadius: BuddyTheme.radiusSM, style: .continuous))
                .foregroundStyle(BuddyTheme.bone)

            Button {
                Task { await send() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(canSend ? BuddyTheme.needle : BuddyTheme.dim.opacity(0.4))
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(!canSend)
            .accessibilityLabel("Send")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(BuddyTheme.canvas.opacity(0.95))
    }

    private var canSend: Bool {
        !isThinking && !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func seedOpeningIfNeeded() {
        guard messages.isEmpty else { return }
        let opening = ChatMessage(
            isUser: false,
            text: BuddyTalkBeat.openingLine(reflection: reflection)
        )
        context.insert(opening)
        try? context.save()
    }

    private func send() async {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        draft = ""
        focused = false
        pending = nil

        let userMsg = ChatMessage(isUser: true, text: text)
        context.insert(userMsg)
        try? context.save()

        isThinking = true
        let reply = await BuddyChatService.reply(message: text, ctx: talkContext)
        isThinking = false

        switch reply {
        case .say(let text):
            context.insert(ChatMessage(isUser: false, text: text))
        case .confirmGoal(let kcal, let text):
            context.insert(ChatMessage(isUser: false, text: text))
            withAnimation(BuddyTheme.easeOut) {
                pending = .goal(kcal: kcal)
            }
        case .confirmLog(let text):
            context.insert(ChatMessage(isUser: false, text: text))
            withAnimation(BuddyTheme.easeOut) {
                pending = .logPlate
            }
        }
        try? context.save()
    }

    private func confirmPending() {
        switch pending {
        case .goal(let kcal):
            if let prefs {
                prefs.dailyCalorieTarget = kcal
            } else {
                context.insert(BuddyPreferences(dailyCalorieTarget: kcal))
            }
            pending = nil
            context.insert(ChatMessage(
                isUser: false,
                text: "Done — daily goal is \(BuddyTalkBeat.formatKcal(kcal)) kcal. Today’s ring uses that now."
            ))
        case .logPlate:
            pending = nil
            context.insert(ChatMessage(
                isUser: false,
                text: "Today’s Log plate is there when you’re ready. I’m with you."
            ))
            router?.openTodayForLogging()
        case nil:
            return
        }
        try? context.save()
    }

    private func dismissPending(announce: Bool) {
        let was = pending
        pending = nil
        guard announce, let was else { return }
        let line: String
        switch was {
        case .goal:
            line = "Okay — left your goal as \(BuddyTalkBeat.formatKcal(target)). Settings gear works too."
        case .logPlate:
            line = "No rush. Say “log a plate” when you want the shortcut."
        }
        context.insert(ChatMessage(isUser: false, text: line))
        try? context.save()
    }

    private func scrollToEnd(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.25)) {
                if isThinking {
                    proxy.scrollTo("thinking", anchor: .bottom)
                } else if let last = messages.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }
}
