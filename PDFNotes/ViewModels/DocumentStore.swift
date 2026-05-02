import Foundation
import PDFKit
#if canImport(PencilKit)
import PencilKit
#endif

@MainActor
final class DocumentStore: ObservableObject {
    @Published var selectedDocument: Document?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var outlineItems: [OutlineItem] = []

    #if os(iOS)
    @Published var currentPageIndex = 1
    let annotationStore = AnnotationStore()
    #endif

private var _pdfDocument: PDFDocument?

    var pdfDocument: PDFDocument? { _pdfDocument }

    func loadDocument(at url: URL) {
        isLoading = true
        errorMessage = nil

        outlineItems.removeAll()

        guard let document = PDFDocument(url: url) else {
            errorMessage = "Unable to open this PDF file."
            isLoading = false
            return
        }

        self._pdfDocument = document
        selectedDocument = Document(url: url)

        #if os(iOS)
        currentPageIndex = 1
        annotationStore.reset()

        let sanitizedName = sanitizeFileName(from: url)
        let annotationsDir = documentsDirectory()
            .appendingPathComponent(sanitizedName, isDirectory: true)
            .appendingPathComponent("annotations", isDirectory: true)
        createDirectoryIfNeeded(annotationsDir)
        annotationStore.baseURL = annotationsDir

        Task {
            await annotationStore.loadDrawings(pageCount: document.pageCount)
        }
        #endif

        outlineItems = OutlineItem.extractAll(from: document)

        isLoading = false
    }

    func reset() {
        #if os(iOS)
        flushAnnotations()
        #endif

        _pdfDocument = nil
        selectedDocument = nil
        errorMessage = nil
        outlineItems.removeAll()

        #if os(iOS)
        currentPageIndex = 1
        annotationStore.reset()
        #endif
    }

    func navigateToPage(_ index: Int) {
        guard let doc = pdfDocument,
              index >= 1, index <= doc.pageCount else { return }

        #if os(iOS)
        flushAnnotations()
        currentPageIndex = index
        #else
        _ = index
        #endif
    }

    #if os(iOS)
    func goToPage(_ index: Int) {
        guard let doc = pdfDocument,
              index >= 1, index <= doc.pageCount else { return }

        flushAnnotations()
        currentPageIndex = index
    }

    func clearAnnotations(page: Int? = nil) {
        if let page = page {
            annotationStore.clearPage(page)
        } else {
            annotationStore.clearAll()
        }
        Task { await annotationStore.saveDirtyDrawings() }
    }

    func markCurrentPageDirty() {
        annotationStore.markDirty(currentPageIndex)
    }

    private func flushAnnotations() {
        if let drawing = annotationStore.drawings[currentPageIndex] {
            annotationStore.setDrawing(drawing, for: currentPageIndex)
        }
        Task { await annotationStore.saveDirtyDrawings() }
    }

    private func documentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    private func sanitizeFileName(from url: URL) -> String {
        var name = url.deletingPathExtension().lastPathComponent
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "\\", with: "_")

        if name.isEmpty {
            name = "untitled"
        }

        return name
    }

    private func createDirectoryIfNeeded(_ url: URL) {
        let fm = FileManager.default
        guard !fm.fileExists(atPath: url.path) else { return }
        try? fm.createDirectory(
            at: url,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }
    #endif
}
