import SwiftUI
import PDFKit

#if os(iOS)
import PencilKit
#endif

#if os(iOS)

class MultiTouchCanvas: PKCanvasView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let touches = event?.allTouches, touches.count > 1 {
            return nil
        }
        return super.hitTest(point, with: event)
    }
}

struct PDFViewRepresentable: UIViewRepresentable {
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

        let canvas = MultiTouchCanvas()
        canvas.translatesAutoresizingMaskIntoConstraints = true
        canvas.isOpaque = false
        canvas.backgroundColor = .clear
        canvas.delegate = context.coordinator
        container.addSubview(canvas)

        NSLayoutConstraint.activate([
            pdfView.topAnchor.constraint(equalTo: container.topAnchor),
            pdfView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            pdfView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        let coordinator = context.coordinator
        coordinator.pdfView = pdfView
        coordinator.canvas = canvas
        coordinator.container = container
        coordinator.annotationsEnabled = annotationsEnabled
        coordinator.currentTool = currentTool
        coordinator.currentColor = currentColor
        annotationStore.canvasView = canvas

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak coordinator] in
            guard let c = coordinator else { return }
            c.syncCanvasToPage(pageIndex: 1)
        }

        coordinator.startPolling()

        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        let coordinator = context.coordinator
        guard let pdfView = coordinator.pdfView else { return }

        if let document = pdfDocument, pdfView.document == nil {
            pdfView.document = document
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak coordinator] in
                guard let c = coordinator else { return }
                c.syncCanvasToPage(pageIndex: c.currentPageIndex)
            }
        }

        coordinator.annotationsEnabled = annotationsEnabled
        coordinator.currentTool = currentTool
        coordinator.currentColor = currentColor

        if coordinator.currentPageIndex != currentPageIndex {
            coordinator.saveCurrentDrawing()
            if let page = pdfView.document?.page(at: currentPageIndex - 1) {
                pdfView.go(to: page)
            }
            coordinator.syncCanvasToPage(pageIndex: currentPageIndex)
        }

        if let canvas = coordinator.canvas {
            if annotationsEnabled {
                canvas.isUserInteractionEnabled = true
                switch currentTool {
                case .pen:
                    canvas.tool = PKInkingTool(.pen, color: currentColor.pkInkColor, width: 5)
                case .highlighter:
                    canvas.tool = PKInkingTool(.marker, color: currentColor.pkInkColor, width: 30)
                case .eraser:
                    canvas.tool = PKEraserTool(.vector)
                }
            } else {
                canvas.isUserInteractionEnabled = false
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(store: annotationStore)
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var pdfView: PDFView?
        var canvas: MultiTouchCanvas?
        var container: UIView?
        var currentPageIndex: Int = 1
        var annotationsEnabled = false
        var currentTool: AnnotationTool = .pen
        var currentColor: AnnotationColor = .blue
        private let store: AnnotationStore

        private var pollTimer: Timer?
        private var lastVisibleRect: CGRect = .zero
        private var lastScaleFactor: CGFloat = 1.0
        private var currentPage: PDFPage?

        init(store: AnnotationStore) {
            self.store = store
        }

        deinit {
            stopPolling()
        }

        func startPolling() {
            pollTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                self?.pollSync()
            }
        }

        func stopPolling() {
            pollTimer?.invalidate()
            pollTimer = nil
        }

        func pollSync() {
            guard let pdfView = pdfView,
                  let canvas = canvas,
                  let container = container,
                  let document = pdfView.document,
                  let page = currentPage ?? pdfView.document?.page(at: currentPageIndex - 1) else { return }

            let pageBounds = page.bounds(for: .mediaBox)
            let visibleRect = pdfView.convert(pageBounds, from: page)

            guard visibleRect.width > 0 && visibleRect.height > 0 else { return }

            currentPage = page

            let scaleFactorChanged = abs(pdfView.scaleFactor - lastScaleFactor) > 0.001
            let positionChanged = abs(visibleRect.origin.x - lastVisibleRect.origin.x) > 0.5
                || abs(visibleRect.origin.y - lastVisibleRect.origin.y) > 0.5

            guard scaleFactorChanged || positionChanged else {
                lastVisibleRect = visibleRect
                return
            }

            let oldFrame = canvas.frame

            if scaleFactorChanged && oldFrame.width > 0 && oldFrame.height > 0 {
                rescaleDrawing(from: oldFrame, to: visibleRect)
            }

            canvas.frame = visibleRect
            lastVisibleRect = visibleRect
            lastScaleFactor = pdfView.scaleFactor
        }

        func syncCanvasToPage(pageIndex: Int) {
            guard let pdfView = pdfView,
                  let canvas = canvas,
                  let container = container,
                  let page = pdfView.document?.page(at: pageIndex - 1) else { return }

            currentPageIndex = pageIndex
            currentPage = page

            let pageBounds = page.bounds(for: .mediaBox)
            let visibleRect = pdfView.convert(pageBounds, from: page)

            canvas.frame = visibleRect
            canvas.drawing = store.drawing(for: pageIndex)
            lastVisibleRect = visibleRect
            lastScaleFactor = pdfView.scaleFactor
        }

        func saveCurrentDrawing() {
            guard let canvas = canvas else { return }
            let drawing = canvas.drawing
            store.setDrawing(drawing, for: currentPageIndex)
            Task { @MainActor in
                await store.saveDirtyDrawings()
            }
        }

        private func rescaleDrawing(from oldFrame: CGRect, to newFrame: CGRect) {
            guard let canvas = canvas,
                  oldFrame.width > 0 && oldFrame.height > 0 else { return }

            let scaleX = newFrame.width / oldFrame.width
            let scaleY = newFrame.height / oldFrame.height

            guard scaleX != 1.0 || scaleY != 1.0 else { return }

            let drawing = canvas.drawing ?? PKDrawing()
            var newStrokes: [PKStroke] = []

            for stroke in drawing.strokes {
                let scaleTransform = CGAffineTransform(scaleX: scaleX, y: scaleY)
                var mutatedStroke = stroke
                mutatedStroke.transform = stroke.transform.concatenating(scaleTransform)
                newStrokes.append(mutatedStroke)
            }

            let transformedDrawing = PKDrawing(strokes: newStrokes)
            canvas.drawing = transformedDrawing
            store.setDrawing(transformedDrawing, for: currentPageIndex)
            Task { @MainActor in
                await store.saveDirtyDrawings()
            }
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
