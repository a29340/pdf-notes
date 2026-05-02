import SwiftUI
import PDFKit

#if os(iOS)
import PencilKit
#endif

#if os(iOS)

class AnnotatingPDFView: PDFView {
    override var canBecomeFirstResponder: Bool { false }
}

struct PDFViewRepresentable: UIViewRepresentable {
    @Binding var currentPageIndex: Int
    var pdfDocument: PDFDocument?
    var annotationStore: AnnotationStore

    func makeUIView(context: Context) -> UIView {
        let container = UIView()

        let pdfView = AnnotatingPDFView()
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
        canvas.isUserInteractionEnabled = true
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
        coordinator.container = container

        let toolPicker = buildToolPicker()
        toolPicker.addObserver(coordinator)
        coordinator.toolPicker = toolPicker
        annotationStore.canvasView = canvas

        coordinator.startPolling()

        DispatchQueue.main.async { [weak coordinator] in
            guard let coordinator else { return }
            _ = canvas.becomeFirstResponder()
            if let selectedTool = toolPicker.selectedToolItem.tool {
                canvas.tool = selectedTool
            }
            toolPicker.setVisible(true, forFirstResponder: canvas)
        }

        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        let coordinator = context.coordinator
        guard let pdfView = coordinator.pdfView else { return }

        if let document = pdfDocument, pdfView.document == nil {
            pdfView.document = document
        }

        if coordinator.currentPageIndex != currentPageIndex {
            coordinator.saveCurrentDrawing()
            if let page = pdfView.document?.page(at: currentPageIndex - 1) {
                pdfView.go(to: page)
            }
            coordinator.syncCanvasToPage(pageIndex: currentPageIndex)
            coordinator.activateCanvas()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(store: annotationStore)
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate, PKToolPickerObserver {
        var pdfView: AnnotatingPDFView?
        var canvas: PKCanvasView?
        var container: UIView?
        var currentPageIndex: Int = 1
        private let store: AnnotationStore
        var toolPicker: PKToolPicker?

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

        func activateCanvas() {
            guard let canvas = canvas else { return }
            if !canvas.isFirstResponder {
                _ = canvas.becomeFirstResponder()
            }
            if let selectedTool = toolPicker?.selectedToolItem.tool {
                canvas.tool = selectedTool
            }
        }

        func pollSync() {
            guard let pdfView = pdfView,
                  let canvas = canvas,
                  let page = currentPage ?? pdfView.document?.page(at: currentPageIndex - 1) else { return }

            let pageBounds = page.bounds(for: .mediaBox)
            let visibleRect = pdfView.convert(pageBounds, from: page)

            guard visibleRect.width > 0 && visibleRect.height > 0 else { return }

            currentPage = page

            let scaleFactorChanged = abs(pdfView.scaleFactor - lastScaleFactor) > 0.001
            let positionChanged = abs(visibleRect.origin.x - lastVisibleRect.origin.x) > 0.5
                || abs(visibleRect.origin.y - lastVisibleRect.origin.y) > 0.5

            guard scaleFactorChanged || positionChanged else { return }

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

            let drawing = canvas.drawing
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

        func toolPickerSelectedToolItemDidChange(_ toolPicker: PKToolPicker) {
            if let selectedTool = toolPicker.selectedToolItem.tool {
                store.canvasView?.tool = selectedTool
            }
        }
    }
}

private func buildToolPicker() -> PKToolPicker {
    let pen = PKToolPickerInkingItem(type: .pen, color: UIColor.black, width: 4)
    let monoline = PKToolPickerInkingItem(type: .monoline, color: UIColor.systemBlue, width: 2, identifier: "com.pdfnotes.monoline")
    let pencil = PKToolPickerInkingItem(type: .pencil, color: UIColor.darkGray, width: 3)
    let marker = PKToolPickerInkingItem(type: .marker, color: UIColor.systemYellow, width: 20)
    let fountainPen = PKToolPickerInkingItem(type: .fountainPen, color: UIColor.systemRed, width: 5, identifier: "com.pdfnotes.fountainpen")
    let watercolor = PKToolPickerInkingItem(type: .watercolor, color: UIColor.systemPurple, width: 10)
    let crayon = PKToolPickerInkingItem(type: .crayon, color: UIColor.systemGreen, width: 8)
    let vectorEraser = PKToolPickerEraserItem(type: .vector)
    let bitmapEraser = PKToolPickerEraserItem(type: .bitmap)

    let items: [PKToolPickerItem] = [
        pen, monoline, pencil,
        marker, fountainPen, watercolor, crayon,
        vectorEraser, bitmapEraser,
    ]

    let picker = PKToolPicker(toolItems: items)
    picker.selectedToolItem = pen
    return picker
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
