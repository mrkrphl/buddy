import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

enum BuddyChatService {
    static func reply(message: String, ctx: BuddyTalkBeat.Context) async -> String {
        let trimmed = BuddyTalkBeat.userPrompt(message)
        guard !trimmed.isEmpty else {
            return BuddyTalkBeat.openingLine(reflection: ctx.reflection)
        }

        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            if let live = await foundationReply(trimmed, ctx: ctx) {
                return live
            }
        }
        #endif

        return BuddyTalkBeat.offlineReply(message: trimmed, ctx: ctx)
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private static func foundationReply(_ message: String, ctx: BuddyTalkBeat.Context) async -> String? {
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available: break
        default: return nil
        }
        do {
            let session = LanguageModelSession(instructions: BuddyTalkBeat.instructions(ctx: ctx))
            let response = try await session.respond(to: message)
            let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty ? nil : String(text.prefix(480))
        } catch {
            return nil
        }
    }
    #endif
}
