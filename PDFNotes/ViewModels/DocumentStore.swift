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
    #if os(iOS)
    @Published var annotationsEnabled = false
    @Published var currentTool: AnnotationTool = .pen
    @Published var currentColor: AnnotationColor = .blue
    @Published var currentPageIndex = 1
    let annotationStore = AnnotationStore()
    #endif

    private var pdfDocument: PDFDocument?

    func loadDocument(at url: URL) {
        isLoading = true
        errorMessage = nil

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
        #endif
        isLoading = false
    }

    func reset() {
        pdfDocument = nil
        selectedDocument = nil
        errorMessage = nil
        #if os(iOS)
        currentPageIndex = 1
        annotationStore.reset()
        annotationsEnabled = false
        currentTool = .pen
        currentColor = .blue
        #endif
    }

    #if os(iOS)
    func toggleAnnotations() {
        annotationsEnabled.toggle()
        if !annotationsEnabled {
            for (page, drawing) in annotationStore.drawings {
                // persist in memory already via annotationStore
            }
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
        currentPageIndex = index
    }

    func clearAnnotations(page: Int? = nil) {
        if let page = page {
            annotationStore.clearPage(page)
        } else {
            annotationStore.clearAll()
        }
    }
    #endif
}
