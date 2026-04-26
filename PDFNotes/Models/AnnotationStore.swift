import Foundation
import PencilKit
import SwiftUI

#if canImport(UIKit)
import UIKit
typealias PlatformColor = UIColor
#else
import AppKit
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

    static let fileExtension = "pencil"

    func setDrawing(_ drawing: PKDrawing, for page: Int) {
        drawings[page] = drawing
        dirtyPages.insert(page)
    }

    func drawing(for page: Int) -> PKDrawing? {
        drawings[page]
    }

    @MainActor
    func saveDirtyDrawings() async {
        guard let baseURL = baseURL else { return }

        for index in dirtyPages {
            guard let drawing = drawings[index] else { continue }
            saveDrawing(drawing, to: baseURL, page: index)
        }
        dirtyPages.removeAll()
    }

    private func saveDrawing(_ drawing: PKDrawing, to baseURL: URL, page: Int) {
        let fileURL = baseURL.appendingPathComponent("page_\(page).\(Self.fileExtension)")
        let data = drawing.dataRepresentation()

        do {
            try data.write(to: fileURL)
        } catch {
            assertionFailure("Failed to save drawing for page \(page): \(error.localizedDescription)")
        }
    }

    private func removeFile(for baseURL: URL, page: Int) {
        let fileURL = baseURL.appendingPathComponent("page_\(page).\(Self.fileExtension)")
        try? FileManager.default.removeItem(at: fileURL)
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

    func loadDrawings(pageCount: Int) async {
        guard let baseURL = baseURL else { return }
        
        drawings.removeAll()
        dirtyPages.removeAll()
        
        for index in 1...pageCount {
            let fileURL = baseURL.appendingPathComponent("page_\(index).\(Self.fileExtension)")
            if FileManager.default.fileExists(atPath: fileURL.path),
               let data = try? Data(contentsOf: fileURL),
               let drawing = try? PKDrawing(data: data) {
                drawings[index] = drawing
            }
        }
    }

    func clearPage(_ page: Int) {
        drawings.removeValue(forKey: page)
        dirtyPages.insert(page)
    }

    func clearAll() {
        drawings.removeAll()
        dirtyPages.removeAll()
    }

    func markDirty(_ page: Int) {
        dirtyPages.insert(page)
    }
}