import SwiftUI

struct OutlineSidebarView: View {
    @EnvironmentObject var store: DocumentStore
    
    var body: some View {
        List {
            ForEach(outlineItems) { item in
                OutlineRowView(item: item)
            }
        }
        .listStyle(.plain)
        .navigationTitle("Contents")
        
        #if os(macOS)
        .frame(minWidth: 250, idealWidth: 300)
        #endif
    }
    
    private var outlineItems: [OutlineItem] {
        store.outlineItems
    }
}

struct OutlineRowView: View {
    let item: OutlineItem
    @EnvironmentObject private var store: DocumentStore
    
    var body: some View {
        if item.children.isEmpty {
            outlineLeaf
                .tag(item.id)
        } else {
            DisclosureGroup(item.title) {
                ForEach(item.children) { child in
                    OutlineRowView(item: child)
                        .padding(.leading, 16)
                }
            }
        }
    }
    
    @ViewBuilder
    private var outlineLeaf: some View {
        let hasDestination = item.destinationPageIndex != nil
        
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
        .contentShape(Rectangle())
        .onTapGesture {
            if let page = item.destinationPageIndex {
                store.navigateToPage(page)
            }
        }
    }
}