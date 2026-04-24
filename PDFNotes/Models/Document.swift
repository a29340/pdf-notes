import Foundation

struct Document {
    let url: URL
    let name: String

    init(url: URL) {
        self.url = url
        self.name = (url.pathExtension.lowercased() == "pdf"
            ? url.deletingPathExtension().lastPathComponent
            : url.lastPathComponent)
    }
}
