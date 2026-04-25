import SwiftUI
#if os(iOS)
import PDFKit
#endif

struct ContentView: View {
    @EnvironmentObject var store: DocumentStore
    @State private var scale: CGFloat = 1.0
    
    #if os(iOS)
    @State private var showOutlineSheet = false
    #endif

    var body: some View {
        Group {
            if let document = store.selectedDocument {
                #if os(iOS)
                pdfVieweriOS(document: document)
                #else
                pdfViewermacOS(document: document)
                #endif
            } else {
                FileBrowserView()
                    .onAppear { store.refreshCloudDocuments() }
            }
        }
    }

    #if os(iOS)
    @ViewBuilder
    private func pdfVieweriOS(document: Document) -> some View {
        guard let pdfDoc = PDFDocument(url: document.url) else {
            return FileBrowserView()
        }

        NavigationSplitView {
            if !store.outlineItems.isEmpty {
                OutlineSidebarView()
                    .navigationSplitViewColumnWidth(min: 200, ideal: 260)
            }
        } detail: {
            ZStack(alignment: .topTrailing) {
                PDFViewRepresentable(
                    scale: $scale,
                    annotationsEnabled: $store.annotationsEnabled,
                    currentTool: $store.currentTool,
                    currentColor: $store.currentColor,
                    currentPageIndex: $store.currentPageIndex,
                    pdfDocument: pdfDoc,
                    annotationStore: store.annotationStore
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if !store.annotationsEnabled {
                    zoomControls
                }
            }
        }
        
        #if os(iOS)
        .safeAreaInset(edge: .bottom) {
            if store.annotationsEnabled {
                AnnotationToolbar(
                    currentTool: $store.currentTool,
                    currentColor: $store.currentColor,
                    currentPageIndex: $store.currentPageIndex,
                    scale: $scale,
                    pageCount: pdfDoc.pageCount,
                    onToolChange: { tool in store.setTool(tool) },
                    onColorChange: { store.cycleColor() },
                    onClearPage: { store.clearAnnotations(page: store.currentPageIndex) },
                    onClearAll: { store.clearAnnotations() },
                    onPagePrev: { store.goToPage(store.currentPageIndex - 1) },
                    onPageNext: { store.goToPage(store.currentPageIndex + 1) },
                    onToggleAnnotations: { store.toggleAnnotations() }
                )
            } else {
                Color.clear.frame(height: 0)
            }
        }
        
        .overlay(alignment: .topLeading) {
            if !store.outlineItems.isEmpty && UIDevice.current.userInterfaceIdiom != .pad {
                outlineButton
            }
        }
        .sheet(isPresented: $showOutlineSheet) {
            NavigationView {
                OutlineSidebarView()
                    .navigationTitle("Contents")
            }
        }
        #endif
    }

    @ViewBuilder
    private var outlineButton: some View {
        Button(action: {}) label: {
            Image(systemName: "list.bullet")
                .font(.title3)
                .padding(8)
                .background(Color.primary.opacity(0.15))
                .clipShape(Circle())
        }
        .onTapGesture { showOutlineSheet = true }
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
            .onTapGesture { scale = max(0.5, scale * 0.8) }

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
            .onTapGesture { scale = min(5.0, scale * 1.25) }

            Button {} label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title3)
                    .padding(8)
                    .background(Color.primary.opacity(0.15))
                    .clipShape(Circle())
            }
            .onTapGesture { scale = 1.0 }

            Button {} label: {
                Image(systemName: "pencil")
                    .font(.title2)
                    .padding(8)
                    .background(Color.orange.opacity(0.15))
                    .clipShape(Circle())
            }
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    store.toggleAnnotations()
                }
            }

            Button {} label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .padding(8)
                    .background(Color.red.opacity(0.15))
                    .clipShape(Circle())
            }
            .onTapGesture { store.reset() }
        }
        .padding(12)
    }
    #endif

    #if os(macOS)
    @ViewBuilder
    private func pdfViewermacOS(document: Document) -> some View {
        guard let pdfDoc = PDFDocument(url: document.url) else {
            return FileBrowserView()
        }

        NavigationSplitView {
            if !store.outlineItems.isEmpty {
                OutlineSidebarView()
                    .navigationSplitViewColumnWidth(min: 200, ideal: 260)
            }
        } detail: {
            ZStack(alignment: .topTrailing) {
                PDFViewRepresentable(
                    scale: $scale,
                    pdfDocument: pdfDoc
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                zoomControlsMac
            }
        }
    }

    @ViewBuilder
    private var zoomControlsMac: some View {
        HStack(spacing: 8) {
            Button {} label: {
                Image(systemName: "minus.magnifyingglass")
                    .font(.title3)
                    .padding(8)
                    .background(Color.primary.opacity(0.15))
                    .clipShape(Circle())
            }
            .onTapGesture { scale = max(0.5, scale * 0.8) }

            Text(String(format: "%.0f%%", scale * 100))
                .font(.caption.monospaced())
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.primary.opacity(0.15))
                .clipShape(Capsule())

            Button {} label: {
                Image(systemName: "plus.magnifyingglass")
                    .font(.title3)
                    .padding(8)
                    .background(Color.primary.opacity(0.15))
                    .clipShape(Circle())
            }
            .onTapGesture { scale = min(5.0, scale * 1.25) }

            Button {} label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title3)
                    .padding(8)
                    .background(Color.primary.opacity(0.15))
                    .clipShape(Circle())
            }
            .onTapGesture { scale = 1.0 }

            Button {} label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .padding(8)
                    .background(Color.red.opacity(0.15))
                    .clipShape(Circle())
            }
            .onTapGesture { store.reset() }
        }
        .padding(12)
    }
    #endif
}

#if os(iOS)
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(DocumentStore())
    }
}
#endif
