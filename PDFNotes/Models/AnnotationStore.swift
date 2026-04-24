import Foundation
import PencilKit

enum AnnotationTool {
    case pen
    case highlighter
    case eraser
}

enum AnnotationColor: CaseIterable {
    case black, blue, red, green, yellow

    var pkColor: UIColor {
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
    var drawings: [Int: PKDrawing] = [:]
    var tool: AnnotationTool = .pen
    var color: AnnotationColor = .blue
    var annotationsEnabled = false

    func drawing(for page: Int) -> PKDrawing {
        return drawings[page] ?? PKDrawing()
    }

    func setDrawing(_ drawing: PKDrawing, for page: Int) {
        if drawing.strokes.isEmpty {
            drawings.removeValue(forKey: page)
        } else {
            drawings[page] = drawing
        }
    }

    func clearPage(_ page: Int) {
        drawings.removeValue(forKey: page)
    }

    func clearAll() {
        drawings.removeAll()
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
    }
}
