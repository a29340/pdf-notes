import Foundation
import AppKit
import PencilKit
import SwiftUI

#if canImport(UIKit)
import UIKit
typealias PlatformColor = UIColor
#else
typealias PlatformColor = NSColor
#endif

enum AnnotationTool {
    case pen
    case highlighter
    case eraser
}

enum AnnotationColor: CaseIterable {
    case black, blue, red, green, yellow

    var pkColor: PlatformColor {
        switch self {
        case .black:  return .black
        case .blue:   return .systemBlue
        case .red:    return .systemRed
        case .green:  return .systemGreen
        case .yellow: return .systemYellow
        }
    }

    var swiftUIColor: Color {
        switch self {
        case .black:  return .black
        case .blue:   return .blue
        case .red:    return .red
        case .green:  return .green
        case .yellow: return .yellow
        }
    }

    var symbolName: String {
        switch self {
        case .black:  return "circle.fill"
        case .blue:   return "circle.fill"
        case .red:    return "circle.fill"
        case .green:  return "circle.fill"
        case .yellow: return "circle.fill"
        }
    }
}

final class AnnotationStore {
    var baseURL: URL?
    var drawings: [Int: PKDrawing] = [:]
    private var dirtyPages: Set<Int> = []
    var tool: AnnotationTool = .pen
    var color: AnnotationColor = .blue
    var annotationsEnabled = false

    func drawing(for page: Int) -> PKDrawing {
        return drawings[page] ?? PKDrawing()
    }

    func setDrawing(_ drawing: PKDrawing, for page: Int) {
        if drawing.strokes.isEmpty {
            if drawings[page] != nil {
                dirtyPages.insert(page)
            }
            drawings.removeValue(forKey: page)
        } else {
            drawings[page] = drawing
            dirtyPages.insert(page)
        }
    }

    func markDirty(_ page: Int) {
        dirtyPages.insert(page)
    }

    func clearPage(_ page: Int) {
        if drawings[page] != nil {
            dirtyPages.insert(page)
        }
        drawings.removeValue(forKey: page)
    }

    func clearAll() {
        for key in drawings.keys {
            dirtyPages.insert(key)
        }
        drawings.removeAll()
    }

    @MainActor
    func saveDirtyDrawings() async {
        guard let baseURL = baseURL, !dirtyPages.isEmpty else { return }

        for page in dirtyPages {
            if let drawing = drawings[page] {
                saveDrawing(drawing, to: baseURL, page: page)
            } else {
                removeFile(for: baseURL, page: page)
            }
        }

        dirtyPages.removeAll()
    }

    @MainActor
    func loadDrawings(pageCount: Int) async {
        #if os(iOS)
        guard let baseURL = baseURL else { return }

        drawings.removeAll()
        dirtyPages.removeAll()

        for index in 1...pageCount {
            if let drawing = loadDrawing(from: baseURL, page: index) {
                drawings[index] = drawing
            }
        }
        #endif
    }

    func nextColor() {
        let allCases = AnnotationColor.allCases
        guard let currentIdx = allCases.firstIndex(of: color) else { return }
        let nextIdx = (currentIdx + 1) % allCases.count
        color = allCases[nextIdx]
    }

    func reset() {
        tool = .pen
        color = .blue
        annotationsEnabled = false
        drawings.removeAll()
        dirtyPages.removeAll()
        baseURL = nil
    }

    // MARK: - File I/O

    private static let fileExtension = "drawing"

    private func fileURL(for page: Int) -> URL {
        return baseURL!.appendingPathComponent("page_\(page).\(Self.fileExtension)")
    }

    private func saveDrawing(_ drawing: PKDrawing, to baseURL: URL, page: Int) {
        guard let data = try? NSKeyedArchiver.archivedData(
            withRootObject: drawing,
            requiringSecureCoding: true
        ) else { return }

        let fileURL = baseURL.appendingPathComponent("page_\(page).\(Self.fileExtension)")
        do {
            try data.write(to: fileURL)
        } catch {
            assertionFailure("Failed to save drawing for page \(page): \(error.localizedDescription)")
        }
    }
    #if os(iOS)
    private func loadDrawing(from baseURL: URL, page: Int) -> PKDrawing? {
        let fileURL = baseURL.appendingPathComponent("page_\(page).\(Self.fileExtension)")

        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let drawing = try? NSKeyedUnarchiver.unarchivedObject(
                  ofClass: PKDrawing.self,
                  from: data
              ) else { return nil }

        return drawing
    }
    #endif

    private func removeFile(for baseURL: URL, page: Int) {
        let fileURL = baseURL.appendingPathComponent("page_\(page).\(Self.fileExtension)")
        try? FileManager.default.removeItem(at: fileURL)
    }
}
