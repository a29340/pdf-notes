import Foundation

#if os(iOS)
import PencilKit
#endif

#if os(iOS)
final class AnnotationStore {
    var baseURL: URL?
    var drawings: [Int: PKDrawing] = [:]
    private var dirtyPages: Set<Int> = []
    weak var canvasView: PKCanvasView?

    func drawing(for page: Int) -> PKDrawing {
        return drawings[page] ?? PKDrawing()
    }

    func setDrawing(_ drawing: PKDrawing, for page: Int) {
        if drawing.strokes.isEmpty {
            if drawings[page] != nil {
                dirtyPages.insert(page)
            }
            drawings.removeValue(forKey: page)
        } else {
            drawings[page] = drawing
            dirtyPages.insert(page)
        }
    }

    func markDirty(_ page: Int) {
        dirtyPages.insert(page)
    }

    func clearPage(_ page: Int) {
        if drawings[page] != nil {
            dirtyPages.insert(page)
        }
        drawings.removeValue(forKey: page)
    }

    func clearAll() {
        for key in drawings.keys {
            dirtyPages.insert(key)
        }
        drawings.removeAll()
    }

    @MainActor
    func saveDirtyDrawings() async {
        guard let baseURL = baseURL, !dirtyPages.isEmpty else { return }

        for page in dirtyPages {
            if let drawing = drawings[page] {
                saveDrawing(drawing, to: baseURL, page: page)
            } else {
                removeFile(for: baseURL, page: page)
            }
        }

        dirtyPages.removeAll()
    }

    @MainActor
    func loadDrawings(pageCount: Int) async {
        guard let baseURL = baseURL else { return }

        drawings.removeAll()
        dirtyPages.removeAll()

        for index in 1...pageCount {
            if let drawing = loadDrawing(from: baseURL, page: index) {
                drawings[index] = drawing
            }
        }
    }

    func reset() {
        drawings.removeAll()
        dirtyPages.removeAll()
        baseURL = nil
        canvasView = nil
    }

    func clearCurrentCanvasPage() {
        canvasView?.drawing = PKDrawing()
    }

    func clearAllCanvases() {
        canvasView?.drawing = PKDrawing()
    }

    private static let fileExtension = "drawing"

    private func saveDrawing(_ drawing: PKDrawing, to baseURL: URL, page: Int) {
        do {
            let data = drawing.dataRepresentation()
            let fileURL = baseURL.appendingPathComponent("page_\(page).\(Self.fileExtension)")
            try data.write(to: fileURL)
        } catch {
            assertionFailure("Failed to save drawing for page \(page): \(error.localizedDescription)")
        }
    }

    private func loadDrawing(from baseURL: URL, page: Int) -> PKDrawing? {
        let fileURL = baseURL.appendingPathComponent("page_\(page).\(Self.fileExtension)")

        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let drawing = try? PKDrawing(data: data) else { return nil }

        return drawing
    }

    private func removeFile(for baseURL: URL, page: Int) {
        let fileURL = baseURL.appendingPathComponent("page_\(page).\(Self.fileExtension)")
        try? FileManager.default.removeItem(at: fileURL)
    }
}
#else
final class AnnotationStore {
    var baseURL: URL?

    func reset() {
        baseURL = nil
    }
}
#endif
