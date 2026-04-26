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
            if store.selectedDocument != nil {
                #if os(iOS)
                documentView
                #else
                documentViewMac
                #endif
            } else {
                FileBrowserView()
            }
        }
    }

    #if os(iOS)
    @ViewBuilder
    private var documentView: some View {
        NavigationStack {
            ZStack(alignment: .topTrailing) {
                PDFViewRepresentable(
                    scale: $scale,
                    annotationsEnabled: $store.annotationsEnabled,
                    currentTool: $store.currentTool,
                    currentColor: $store.currentColor,
                    currentPageIndex: $store.currentPageIndex,
                    pdfDocument: store.pdfDocument,
                    annotationStore: store.annotationStore
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                VStack {
                    HStack {
                        if !store.annotationsEnabled {
                            zoomControls
                        }
                        Spacer()
                    }
                    Spacer()
                }
            }
            .safeAreaInset(edge: .bottom) {
                if store.annotationsEnabled {
                    AnnotationToolbar(
                        currentTool: $store.currentTool,
                        currentColor: $store.currentColor,
                        currentPageIndex: $store.currentPageIndex,
                        scale: $scale,
                        pageCount: store.pdfDocument?.pageCount ?? 0,
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
                NavigationStack {
                    OutlineSidebarView()
                        .navigationTitle("Contents")
                }
            }
        }
    }

    @ViewBuilder
    private var outlineButton: some View {
        Button {
            showOutlineSheet = true
        } label: {
            Image(systemName: "list.bullet")
                .font(.title3)
                .padding(8)
                .background(Color.primary.opacity(0.15))
                .clipShape(Circle())
        }
    }

    @ViewBuilder
    private var zoomControls: some View {
        HStack(spacing: 8) {
            Button {
                scale = max(0.5, scale - 0.25)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.title2)
            }
            
            Button {
                scale = 1.0
            } label: {
                Text("\(Int(scale * 100))%")
                    .font(.caption)
            }
            
            Button {
                scale = min(5.0, scale + 0.25)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
            }

            Button {
                scale = 1.0
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title3)
            }

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    store.toggleAnnotations()
                }
            } label: {
                Image(systemName: "pencil")
                    .font(.title2)
                    .foregroundColor(.orange)
            }

            Button {
                store.reset()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.red)
            }
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    #endif

    #if os(macOS)
    @ViewBuilder
    private var documentViewMac: some View {
        NavigationStack {
            ZStack(alignment: .topTrailing) {
                PDFViewRepresentable(
                    scale: $scale,
                    pdfDocument: store.pdfDocument
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                zoomControlsMac
            }
        }
    }

    @ViewBuilder
    private var zoomControlsMac: some View {
        HStack(spacing: 8) {
            Button {
                scale = max(0.5, scale * 0.8)
            } label: {
                Image(systemName: "minus.magnifyingglass")
                    .font(.title3)
                    .padding(8)
                    .background(Color.primary.opacity(0.15))
                    .clipShape(Circle())
            }

            Text(String(format: "%.0f%%", scale * 100))
                .font(.caption.monospaced())
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.primary.opacity(0.15))
                .clipShape(Capsule())

            Button {
                scale = min(5.0, scale * 1.25)
            } label: {
                Image(systemName: "plus.magnifyingglass")
                    .font(.title3)
                    .padding(8)
                    .background(Color.primary.opacity(0.15))
                    .clipShape(Circle())
            }

            Button {
                scale = 1.0
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title3)
                    .padding(8)
                    .background(Color.primary.opacity(0.15))
                    .clipShape(Circle())
            }

            Button {
                store.reset()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .padding(8)
                    .background(Color.red.opacity(0.15))
                    .clipShape(Circle())
            }
        }
        .padding(12)
    }
    #endif
}