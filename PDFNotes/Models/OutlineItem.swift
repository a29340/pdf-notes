import Foundation
import PDFKit

struct OutlineItem: Identifiable {
    let id = UUID()
    let title: String
    var children: [OutlineItem]
    let destinationPageIndex: Int?
}

extension OutlineItem {
    init(pdfOutline: PDFOutline, document: PDFDocument?) {
        self.title = pdfOutline.label ?? ""
        
        var pageIndex: Int? = nil
        if let page = pdfOutline.destination?.page,
           let doc = document {
            if let pageRef = page.pageRef {
                for i in 0..<doc.pageCount {
                    if doc.page(at: i)?.pageRef == pageRef {
                        pageIndex = i + 1
                        break
                    }
                }
            }
        }
        self.destinationPageIndex = pageIndex
        
        var children: [OutlineItem] = []
        for i in 0..<pdfOutline.numberOfChildren {
            if let child = pdfOutline.child(at: i) {
                children.append(OutlineItem(pdfOutline: child, document: document))
            }
        }
        self.children = children
    }
    
    static func extractAll(from document: PDFDocument) -> [OutlineItem] {
        var items: [OutlineItem] = []
        
        guard let rootOutline = document.outlineRoot else { return items }
        
        for i in 0..<rootOutline.numberOfChildren {
            if let outline = rootOutline.child(at: i) {
                items.append(OutlineItem(pdfOutline: outline, document: document))
            }
        }
        
        return items
    }
}
