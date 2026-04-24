import SwiftUI
import PDFKit

#if os(iOS)
struct PDFViewRepresentable: UIViewRepresentable {
    @Binding var scale: CGFloat
    var pdfDocument: PDFDocument?

    func makeUIView(context: Context) -> UIView {
        let container = UIView()

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.showsVerticalScrollIndicator = true
        container.addSubview(scrollView)

        let pdfView = PDFView()
        pdfView.autoScales = false
        pdfView.displayMode = .singlePage
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(pdfView)

        if let document = pdfDocument {
            pdfView.document = document
        }

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: container.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            pdfView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            pdfView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            pdfView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            pdfView.widthAnchor.constraint(greaterThanOrEqualTo: scrollView.widthAnchor),
        ])

        let gesture = UIPinchGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePinch(_:))
        )
        pdfView.addGestureRecognizer(gesture)

        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let scrollView = uiView.subviews.first as? UIScrollView,
              let pdfView = scrollView.subviews.first as? PDFView else { return }

        if let document = pdfDocument, pdfView.document == nil {
            pdfView.document = document
        }

        let clampedScale = max(0.5, min(scale, 5.0))
        pdfView.magnification = clampedScale
        scrollView.contentSize = CGSize(
            width: pdfView.bounds.width * clampedScale,
            height: pdfView.bounds.height * clampedScale
        )
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(scaleBinding: $scale)
    }

    final class Coordinator {
        private var scaleBinding: Binding<CGFloat>

        init(scaleBinding: Binding<CGFloat>) {
            self.scaleBinding = scaleBinding
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            if gesture.state == .changed || gesture.state == .ended {
                scaleBinding.wrappedValue *= gesture.scale
                gesture.scale = 1.0
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
        pdfView.displaysToolbar = false
        pdfView.displaysPageField = false
        pdfView.displaysBookmarkBar = false

        if let document = pdfDocument {
            pdfView.document = document
        }

        return pdfView
    }

    func updateNSView(_ nsView: PDFView, context: Context) {
        if let document = pdfDocument, nsView.document == nil {
            nsView.document = document
        }
        nsView.magnification = scale
    }
}
#endif
