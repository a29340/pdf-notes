import Foundation
import PDFKit

struct OutlineItem: Identifiable {
    let id = UUID()
    let title: String
    var children: [OutlineItem]
    let destinationPageIndex: Int?
}

extension OutlineItem {
    init(pdfOutline: PDFOutline, document: PDFDocument? = nil) {
        self.title = pdfOutline.label ?? ""
        
        if let page = pdfOutline.destination?.page {
            if let doc = document {
                self.destinationPageIndex = doc.index(for: page) + 1
            } else {
                self.destinationPageIndex = nil
            }
        } else {
            self.destinationPageIndex = nil
        }
        
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
        
        guard let rootOutlines = document.outlineRoot else { return items }
        
        for i in 0..<rootOutlines.numberOfChildren {
            if let outline = rootOutlines.child(at: i) {
                items.append(OutlineItem(pdfOutline: outline, document: document))
            }
        }
        
        return items
    }
}