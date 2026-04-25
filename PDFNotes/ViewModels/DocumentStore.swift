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
    @Published var cloudDocuments: [Document] = []

    #if os(iOS)
    @Published var annotationsEnabled = false
    @Published var currentTool: AnnotationTool = .pen
    @Published var currentColor: AnnotationColor = .blue
    @Published var currentPageIndex = 1
    let annotationStore = AnnotationStore()
    #endif

    private var pdfDocument: PDFDocument?
    private let cloudManager = CloudDocumentManager.shared

    init() {
        _ = cloudManager.initialize(bundleID: Bundle.main.bundleIdentifier ?? "com.pdfnotes.app")
    }

    func refreshCloudDocuments() {
        cloudDocuments = cloudManager.listDocuments()
    }

    func loadDocument(at url: URL) {
        isLoading = true
        errorMessage = nil
        outlineItems.removeAll()

        guard let document = PDFDocument(url: url) else {
            errorMessage = "Unable to open this PDF file."
            isLoading = false
            return
        }

        self.pdfDocument = document
        selectedDocument = Document(url: url)

        #if os(iOS)
        currentPageIndex = 1
        annotationStore.reset()

        guard let annotationsDir = cloudManager.createAnnotationsDirectory(
            for: selectedDocument!
        ) else {
            errorMessage = "Unable to create annotation storage."
            isLoading = false
            return
        }
        annotationStore.baseURL = annotationsDir

        Task {
            await annotationStore.loadDrawings(pageCount: document.pageCount)
        }
        #endif

        outlineItems = OutlineItem.extractAll(from: document)
        isLoading = false
    }

    func loadFromCloud(_ doc: Document) {
        guard let cloudURL = cloudManager.containerURL else { return }

        if doc.url.absoluteString.contains(cloudURL.absoluteString) {
            loadDocument(at: doc.url)
        } else {
            errorMessage = "Document is not in iCloud storage."
        }
    }

    func importToCloud(from url: URL, overwrite: Bool = false) {
        let accessGranted = url.startAccessingSecurityScopedResource()
        var tempURL: URL?

        if accessGranted {
            let fm = FileManager.default
            let cacheDir = fm.urls(for: .cachesDirectory, in: .userDomainMask).first!
            tempURL = cacheDir.appendingPathComponent(url.lastPathComponent)

            do {
                try fm.copyItem(at: url, to: tempURL!)
            } catch {
                accessGranted ? url.stopAccessingSecurityScopedResource() : ()
                errorMessage = "Failed to copy document."
                return
            }

            if let iCloudURL = cloudManager.copyDocument(from: tempURL!, overwrite: overwrite) {
                try? fm.removeItem(at: tempURL!)
                loadDocument(at: iCloudURL)
                refreshCloudDocuments()
            } else {
                try? fm.removeItem(at: tempURL!)
                errorMessage = "A document with this name already exists."
            }

            url.stopAccessingSecurityScopedResource()
        } else {
            if let iCloudURL = cloudManager.copyDocument(from: url, overwrite: overwrite) {
                loadDocument(at: iCloudURL)
                refreshCloudDocuments()
            } else {
                errorMessage = "A document with this name already exists."
            }
        }
    }

    func deleteFromCloud(_ doc: Document) {
        if cloudManager.deleteDocument(doc) {
            refreshCloudDocuments()
        }
    }

    func reset() {
        #if os(iOS)
        flushAnnotations()
        #endif

        pdfDocument = nil
        selectedDocument = nil
        errorMessage = nil
        outlineItems.removeAll()

        #if os(iOS)
        currentPageIndex = 1
        annotationStore.reset()
        annotationsEnabled = false
        currentTool = .pen
        currentColor = .blue
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
    func toggleAnnotations() {
        annotationsEnabled.toggle()
        if !annotationsEnabled {
            flushAnnotations()
        }
    }

    func setTool(_ tool: AnnotationTool) {
        currentTool = tool
    }

    func cycleColor() {
        annotationStore.nextColor()
        currentColor = annotationStore.color
    }

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
    #endif
}
