import Foundation
import PDFKit

struct OutlineItem: Identifiable {
    let id = UUID()
    let title: String
    var children: [OutlineItem]
    let destinationPageIndex: Int?
}

#if os(iOS)
extension OutlineItem {
    init(pdfOutline: PDFOutline) {
        self.title = pdfOutline.label ?? ""
        
        if let page = pdfOutline.destination?.page,
           let pageIndex = page.pageIndex {
            self.destinationPageIndex = Int(pageIndex) + 1
        } else {
            self.destinationPageIndex = nil
        }
        
        var children: [OutlineItem] = []
        for i in 0..<pdfOutline.childrenCount {
            if let child = pdfOutline.child(at: i) {
                children.append(OutlineItem(pdfOutline: child))
            }
        }
        self.children = children
    }
    
    static func extractAll(from document: PDFDocument) -> [OutlineItem] {
        var items: [OutlineItem] = []
        
        guard let rootOutlines = document.outlineItems else { return items }
        
        for i in 0..<rootOutlines.count {
            if let outline = rootOutlines[i] as? PDFOutline {
                items.append(OutlineItem(pdfOutline: outline))
            }
        }
        
        return items
    }
}
#else
extension OutlineItem {
    static func extractAll(from document: PDFDocument) -> [OutlineItem] {
        return []
    }
}
#endif