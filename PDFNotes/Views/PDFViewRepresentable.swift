import SwiftUI
import PDFKit
#if os(iOS)
import PencilKit
#endif

#if os(iOS)
struct PDFViewRepresentable: UIViewRepresentable {
    @Binding var scale: CGFloat
    @Binding var annotationsEnabled: Bool
    @Binding var currentTool: AnnotationTool
    @Binding var currentColor: AnnotationColor
    @Binding var currentPageIndex: Int
    var pdfDocument: PDFDocument?
    var annotationStore: AnnotationStore

    func makeUIView(context: Context) -> UIView {
        let pdfView = PDFView()
        pdfView.autoScales = false
        pdfView.displayMode = .singlePage
        pdfView.translatesAutoresizingMaskIntoConstraints = false

        if let document = pdfDocument {
            pdfView.document = document
        }

        return pdfView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let pdfView = uiView as? PDFView else { return }

        if let document = pdfDocument, pdfView.document == nil {
            pdfView.document = document
        }

        let clampedScale = max(0.5, min(scale, 5.0))
        pdfView.scaleFactor = clampedScale
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(store: annotationStore)
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        private let store: AnnotationStore

        init(store: AnnotationStore) {
            self.store = store
        }
    }
}
#endif

#if os(macOS)
struct PDFViewRepresentable: NSViewRepresentable {
    @Binding var scale: CGFloat
    var pdfDocument: PDFDocument?

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage

        if let document = pdfDocument {
            pdfView.document = document
        }

        return pdfView
    }

    func updateNSView(_ nsView: PDFView, context: Context) {
        if let document = pdfDocument, nsView.document == nil {
            nsView.document = document
        }
    }
}
#endif