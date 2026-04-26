import Foundation

struct Document: Equatable {
    let url: URL
    let name: String

    init(url: URL) {
        self.url = url
        self.name = (url.pathExtension.lowercased() == "pdf"
            ? url.deletingPathExtension().lastPathComponent
            : url.lastPathComponent)
    }
}
