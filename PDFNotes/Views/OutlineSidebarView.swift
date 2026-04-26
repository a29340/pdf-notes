import SwiftUI

struct OutlineSidebarView: View {
    @EnvironmentObject var store: DocumentStore
    
    var body: some View {
        List {
            ForEach(store.outlineItems) { item in
                OutlineItemRow(item: item)
            }
        }
    }
}

struct OutlineItemRow: View {
    let item: OutlineItem
    
    var body: some View {
        if item.children.isEmpty {
            leafRow
        } else {
            groupRow
        }
    }
    
    @ViewBuilder
    private var groupRow: some View {
        DisclosureGroup(item.title) {
            ForEach(item.children) { child in
                OutlineItemRow(item: child)
            }
        }
    }
    
    @ViewBuilder
    private var leafRow: some View {
        HStack {
            Image(systemName: "bookmark")
            Text(item.title)
            Spacer()
            if let page = item.destinationPageIndex {
                Text("\(page)")
            }
        }
    }
}