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
        let container = UIView()

        let pdfView = PDFView()
        pdfView.autoScales = false
        pdfView.displayMode = .singlePage
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(pdfView)

        if let document = pdfDocument {
            pdfView.document = document
        }

        let canvas = PKCanvasView()
        canvas.translatesAutoresizingMaskIntoConstraints = false
        canvas.isOpaque = false
        canvas.backgroundColor = .clear
        canvas.delegate = context.coordinator
        container.addSubview(canvas)

        NSLayoutConstraint.activate([
            pdfView.topAnchor.constraint(equalTo: container.topAnchor),
            pdfView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            pdfView.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            canvas.topAnchor.constraint(equalTo: container.topAnchor),
            canvas.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            canvas.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            canvas.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        let coordinator = context.coordinator
        coordinator.pdfView = pdfView
        coordinator.canvas = canvas
        coordinator.currentPageIndex = 1

        canvas.isHidden = true

        let initialDrawing = self.annotationStore.drawing(for: 1)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak canvas, weak pdfView] in
            guard let page = pdfView?.document?.page(at: 0),
                  let canvas = canvas,
                  let pdfView = pdfView else { return }
            let pageBounds = page.bounds(for: .mediaBox)
            let scale = pdfView.scaleFactor
            let targetFrame = CGRect(
                x: 0,
                y: 0,
                width: pageBounds.width * scale,
                height: pageBounds.height * scale
            )
            canvas.frame = targetFrame
            canvas.drawing = initialDrawing
        }

        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        let coordinator = context.coordinator
        guard let pdfView = coordinator.pdfView,
              let canvas = coordinator.canvas else { return }

        if let document = pdfDocument, pdfView.document == nil {
            pdfView.document = document
        }

        let clampedScale = max(0.5, min(scale, 5.0))
        pdfView.scaleFactor = clampedScale

        synchronizeCanvas(
            coordinator: coordinator,
            canvas: canvas,
            pdfView: pdfView,
            targetPage: currentPageIndex
        )

        canvas.isHidden = !annotationsEnabled

        for gr in pdfView.gestureRecognizers ?? [] {
            gr.isEnabled = !annotationsEnabled
        }

        if annotationsEnabled {
            updateTool(canvas: canvas)
        }
    }

    private func synchronizeCanvas(
        coordinator: Coordinator,
        canvas: PKCanvasView,
        pdfView: PDFView,
        targetPage: Int
    ) {
        guard coordinator.currentPageIndex != targetPage else { return }

        let drawing = canvas.drawing
        annotationStore.setDrawing(drawing, for: coordinator.currentPageIndex)

        if let page = pdfView.document?.page(at: targetPage - 1) {
            pdfView.go(to: page)
        }

        coordinator.currentPageIndex = targetPage

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak canvas, weak pdfView] in
            guard let canvas = canvas,
                  let pdfView = pdfView,
                  let _ = pdfView.document?.page(at: targetPage - 1) else { return }

            if let pageBounds = pdfView.document?.page(at: targetPage - 1)?.bounds(for: .mediaBox) {
                let scale = pdfView.scaleFactor
                let targetFrame = CGRect(
                    x: 0,
                    y: 0,
                    width: pageBounds.width * scale,
                    height: pageBounds.height * scale
                )
                canvas.frame = targetFrame
                canvas.drawing = self.annotationStore.drawing(for: targetPage)
            }
        }
    }

    private func updateTool(canvas: PKCanvasView) {
        switch currentTool {
        case .pen:
            canvas.tool = PKInkingTool(.pen, color: currentColor.pkInkColor, width: 5)
        case .highlighter:
            canvas.tool = PKInkingTool(.marker, color: currentColor.pkInkColor, width: 30)
        case .eraser:
            canvas.tool = PKEraserTool(.vector)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(store: annotationStore)
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var pdfView: PDFView?
        var canvas: PKCanvasView?
        var currentPageIndex: Int = 1
        private let store: AnnotationStore

        init(store: AnnotationStore) {
            self.store = store
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            let drawing = canvasView.drawing
            store.setDrawing(drawing, for: currentPageIndex)
            Task { @MainActor in
                await store.saveDirtyDrawings()
            }
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
        nsView.scaleFactor = scale
    }
}
#endif