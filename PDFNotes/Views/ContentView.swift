import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: DocumentStore
    @State private var scale: CGFloat = 1.0

    var body: some View {
        Group {
            if let document = store.selectedDocument,
               let pdfDoc = PDFDocument(url: document.url) {
                pdfViewer(pdfDoc: pdfDoc)
            } else {
                FileBrowserView()
            }
        }
    }

    @ViewBuilder
    private func pdfViewer(pdfDoc: PDFDocument) -> some View {
        ZStack(alignment: .topTrailing) {
            PDFViewRepresentable(
                scale: $scale,
                pdfDocument: pdfDoc
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            zoomControls
        }
    }

    @ViewBuilder
    private var zoomControls: some View {
        HStack(spacing: 8) {
            Button {} label: {
                Image(systemName: "minus.circle.fill")
                    .font(.title2)
                    .padding(8)
                    .background(Color.primary.opacity(0.15))
                    .clipShape(Circle())
            }
            .symbolRenderingMode(.palette)
            .onTapGesture {
                scale = max(0.5, scale * 0.8)
            }

            Text(String(format: "%.0f%%", scale * 100))
                .font(.caption.monospaced())
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.primary.opacity(0.15))
                .clipShape(Capsule())

            Button {} label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .padding(8)
                    .background(Color.primary.opacity(0.15))
                    .clipShape(Circle())
            }
            .symbolRenderingMode(.palette)
            .onTapGesture {
                scale = min(5.0, scale * 1.25)
            }

            Button {} label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title3)
                    .padding(8)
                    .background(Color.primary.opacity(0.15))
                    .clipShape(Circle())
            }
            .onTapGesture {
                scale = 1.0
            }

            Button {} label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .padding(8)
                    .background(Color.red.opacity(0.15))
                    .clipShape(Circle())
            }
            .onTapGesture {
                store.reset()
            }
        }
        .padding(12)
    }
}

#if os(iOS)
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(DocumentStore())
    }
}
#endif
