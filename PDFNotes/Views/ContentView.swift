import SwiftUI

#if os(iOS)
import PDFKit
#endif

struct ContentView: View {
    @EnvironmentObject var store: DocumentStore

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
                    currentPageIndex: $store.currentPageIndex,
                    pdfDocument: store.pdfDocument,
                    annotationStore: store.annotationStore
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .safeAreaInset(edge: .bottom) {
                AnnotationToolbar(
                    currentPageIndex: $store.currentPageIndex,
                    pageCount: store.pdfDocument?.pageCount ?? 0,
                    onClearPage: {
                        store.annotationStore.clearCurrentCanvasPage()
                        store.clearAnnotations(page: store.currentPageIndex)
                    },
                    onClearAll: {
                        store.annotationStore.clearAllCanvases()
                        store.clearAnnotations()
                    },
                    onPagePrev: { store.goToPage(store.currentPageIndex - 1) },
                    onPageNext: { store.goToPage(store.currentPageIndex + 1) },
                    onCloseDocument: { store.reset() }
                )
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
    #endif

    #if os(macOS)
    @ViewBuilder
    private var documentViewMac: some View {
        NavigationStack {
            ZStack(alignment: .topTrailing) {
                PDFViewRepresentable(
                    pdfDocument: store.pdfDocument
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Button {
                    store.reset()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                        .padding(8)
                        .background(Color.primary.opacity(0.15))
                        .clipShape(Circle())
                }
            }
        }
    }
    #endif
}
