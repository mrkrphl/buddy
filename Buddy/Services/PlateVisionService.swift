import UIKit
import Vision

enum PlateVisionService {
    enum VisionError: LocalizedError {
        case noCGImage
        case failed

        var errorDescription: String? {
            switch self {
            case .noCGImage: return "Couldn’t read that photo."
            case .failed: return "Plate vision failed."
            }
        }
    }

    /// Classify + OCR a plate photo into a short text description for FM.
    static func describe(_ image: UIImage) async throws -> String {
        guard let cg = image.cgImage else { throw VisionError.noCGImage }

        async let classify = classifyLabels(cg)
        async let text = recognizeText(cg)
        let (labels, ocr) = try await (classify, text)

        var parts: [String] = []
        if !labels.isEmpty {
            parts.append("Visible: " + labels.joined(separator: ", "))
        }
        if !ocr.isEmpty {
            parts.append("Text on/near plate: " + ocr)
        }
        if parts.isEmpty {
            parts.append("A plated meal photo with no strong labels.")
        }
        return parts.joined(separator: "\n")
    }

    private static func classifyLabels(_ cg: CGImage) async throws -> [String] {
        try await withCheckedThrowingContinuation { cont in
            let request = VNClassifyImageRequest { request, error in
                if let error {
                    cont.resume(throwing: error)
                    return
                }
                let results = (request.results as? [VNClassificationObservation]) ?? []
                let top = results
                    .prefix(8)
                    .filter { $0.confidence >= 0.15 }
                    .map { "\($0.identifier) (\(String(format: "%.0f", $0.confidence * 100))%)" }
                cont.resume(returning: Array(top))
            }
            let handler = VNImageRequestHandler(cgImage: cg, options: [:])
            do {
                try handler.perform([request])
            } catch {
                cont.resume(throwing: error)
            }
        }
    }

    private static func recognizeText(_ cg: CGImage) async throws -> String {
        try await withCheckedThrowingContinuation { cont in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    cont.resume(throwing: error)
                    return
                }
                let observations = (request.results as? [VNRecognizedTextObservation]) ?? []
                let lines = observations.compactMap { $0.topCandidates(1).first?.string }
                cont.resume(returning: lines.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines))
            }
            request.recognitionLevel = .accurate
            let handler = VNImageRequestHandler(cgImage: cg, options: [:])
            do {
                try handler.perform([request])
            } catch {
                cont.resume(throwing: error)
            }
        }
    }
}
