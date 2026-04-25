import SwiftUI

struct OutlineSidebarView: View {
    @EnvironmentObject var store: DocumentStore
    
    var body: some View {
        List(outlineItems) { item in
            outlineRow(item: item)
        }
        .listStyle(.plain)
        .navigationTitle("Contents")
        .navigationBarTitleDisplayMode(.inline)
        
        #if os(macOS)
        .frame(minWidth: 250, idealWidth: 300)
        #endif
    }
    
    @ViewBuilder
    private func outlineRow(item: OutlineItem) -> some View {
        if item.children.isEmpty {
            outlineLeaf(item: item)
                .tag(item.id)
        } else {
            DisclosureGroup(item.title) {
                ForEach(item.children) { child in
                    outlineRow(item: child)
                        .padding(.leading, 16)
                }
            }
        }
    }
    
    @ViewBuilder
    private func outlineLeaf(item: OutlineItem) -> some View {
        let hasDestination = item.destinationPageIndex != nil
        
        Button(action: {}) label: {
            HStack(spacing: 8) {
                Image(systemName: "bookmark")
                    .frame(width: 20)
                
                Text(item.title.isEmpty ? "(untitled)" : item.title)
                    .lineLimit(1)
                    .foregroundColor(hasDestination ? .primary : .secondary)
                
                Spacer()
                
                if let page = item.destinationPageIndex {
                    Text("\(page)")
                        .font(.caption.monospaced())
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
        .buttonStyle(.plain)
        
        #if os(iOS)
        .onTapGesture {
            if let page = item.destinationPageIndex {
                store.navigateToPage(page)
            }
        }
        #endif
        
        #if os(macOS)
        .onTapGesture {
            if let page = item.destinationPageIndex {
                store.navigateToPage(page)
            }
        }
        #endif
    }
    
    private var outlineItems: [OutlineItem] {
        store.outlineItems
    }
}
