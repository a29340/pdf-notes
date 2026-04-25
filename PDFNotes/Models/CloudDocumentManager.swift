import Foundation

final class CloudDocumentManager {
    static let shared = CloudDocumentManager()

    private(set) var containerURL: URL?
    private(set) var documentsURL: URL?

    @MainActor
    func initialize(bundleID: String) -> Bool {
        guard let container = FileManager.default.url(
            forUbiquityContainerIdentifier: "iCloud.com.pdfnotes.app"
        ) else {
            assertionFailure("iCloud ubiquity container not available. Check provisioning profile.")
            return false
        }

        self.containerURL = container
        self.documentsURL = container.appendingPathComponent("Documents", isDirectory: true)

        let fm = FileManager.default
        if !fm.fileExists(atPath: documentsURL!.path) {
            try? fm.createDirectory(
                at: documentsURL!,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }

        return true
    }

    @MainActor
    func listDocuments() -> [Document] {
        guard let docsURL = documentsURL else { return [] }

        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(
            at: docsURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: .skipsHiddenFiles
        ) else { return [] }

        var results: [Document] = []

        for url in contents where url.pathExtension.lowercased() == "pdf" {
            if downloadIfNeeded(url) {
                let doc = Document(url: url)
                results.append(doc)
            }
        }

        results.sort { $0.name < $1.name }
        return results
    }

    @MainActor
    func copyDocument(from sourceURL: URL, overwrite: Bool = false) -> URL? {
        guard let docsURL = documentsURL else { return nil }

        let fm = FileManager.default
        var name = sourceURL.deletingPathExtension().lastPathComponent
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "\\", with: "_")

        if name.isEmpty { name = "untitled" }

        let destURL = docsURL.appendingPathComponent(name + ".pdf")

        if fm.fileExists(atPath: destURL.path) && !overwrite {
            return nil
        }

        do {
            if fm.fileExists(atPath: destURL.path) {
                try fm.removeItem(at: destURL)
            }
            try fm.copyItem(at: sourceURL, to: destURL)
            return destURL
        } catch {
            assertionFailure("Failed to copy document to iCloud: \(error.localizedDescription)")
            return nil
        }
    }

    @MainActor
    func deleteDocument(_ doc: Document) -> Bool {
        let fm = FileManager.default
        do {
            try fm.removeItem(at: doc.url)
        } catch {
            assertionFailure("Failed to delete document: \(error.localizedDescription)")
            return false
        }
        return true
    }

    @MainActor
    func annotationsDirectory(for doc: Document) -> URL? {
        let sanitizedName = sanitizeFileName(from: doc.url)
        return documentsURL?
            .appendingPathComponent(sanitizedName, isDirectory: true)
            .appendingPathComponent("annotations", isDirectory: true)
    }

    func createAnnotationsDirectory(for doc: Document) -> URL? {
        guard let annotationsDir = annotationsDirectory(for: doc),
              let docsURL = documentsURL else { return nil }

        let fm = FileManager.default
        let parentDir = docsURL.appendingPathComponent(
            sanitizeFileName(from: doc.url), isDirectory: true
        )

        if !fm.fileExists(atPath: parentDir.path) {
            try? fm.createDirectory(
                at: parentDir,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }

        if !fm.fileExists(atPath: annotationsDir.path) {
            try? fm.createDirectory(
                at: annotationsDir,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }

        return annotationsDir
    }

    // MARK: - Helpers

    private func downloadIfNeeded(_ url: URL) -> Bool {
        do {
            let resourceValues = try url.resourceValues(forKeys: [.ubiquitousItemIsDownloadedKey])
            if !resourceValues.ubiquitousItemIsDownloaded ?? true {
                FileManager.default.startDownloadingUbiquitousItem(
                    at: url,
                    options: []
                ) { success in
                    if success {
                        print("[iCloud] Downloaded: \(url.lastPathComponent)")
                    } else {
                        print("[iCloud] Failed to download: \(url.lastPathComponent)")
                    }
                }
                return false
            }
        } catch {
            assertionFailure("Failed to check download status: \(error.localizedDescription)")
            return true
        }

        if FileManager.default.fileExists(atPath: url.path) {
            return true
        }
        return false
    }

    private func sanitizeFileName(from url: URL) -> String {
        var name = url.deletingPathExtension().lastPathComponent
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "\\", with: "_")

        if name.isEmpty { name = "untitled" }
        return name
    }
}
