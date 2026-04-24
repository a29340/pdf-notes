import Foundation
import Combine
import PDFKit

@MainActor
final class DocumentStore: ObservableObject {
    @Published var selectedDocument: Document?
    @Published var isLoading = false
    @Published var errorMessage: String?

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
        isLoading = false
    }

    func reset() {
        pdfDocument = nil
        selectedDocument = nil
        errorMessage = nil
    }
}
