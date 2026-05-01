import SwiftUI

#if os(iOS)

struct AnnotationToolbar: View {
    var annotationsEnabled: Bool
    @Binding var currentTool: AnnotationTool
    @Binding var currentColor: AnnotationColor
    @Binding var currentPageIndex: Int
    var pageCount: Int
    var onToolChange: (AnnotationTool) -> Void
    var onColorChange: () -> Void
    var onClearPage: () -> Void
    var onClearAll: () -> Void
    var onPagePrev: () -> Void
    var onPageNext: () -> Void
    var onToggleAnnotations: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if annotationsEnabled {
                primaryControls
                Divider()
                    .background(Color.white.opacity(0.3))
                secondaryControls
            } else {
                visualizationControls
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(UIColor.systemGray5))
        .clipShape(RoundedCorners(radius: 12, corners: [.topLeft, .topRight]))
    }

    private var primaryControls: some View {
        HStack(spacing: 0) {
            HStack(spacing: 8) {
                toolButton(.pen, "pencil", label: "Pen")
                toolButton(.highlighter, "highlighter", label: "Highlight")
                toolButton(.eraser, "eraser.fill", label: "Eraser")
            }

            Spacer()

            colorPicker

            Spacer(minLength: 12)

            pageIndicator
        }
        .padding(.vertical, 4)
    }

    private var secondaryControls: some View {
        HStack(spacing: 0) {
            HStack(spacing: 8) {
                navButton(action: onPagePrev, icon: "chevron.left", label: "Prev")
                    .disabled(currentPageIndex <= 1)

                navButton(action: onPageNext, icon: "chevron.right", label: "Next")
                    .disabled(currentPageIndex >= pageCount)
            }

            Spacer()

            HStack(spacing: 8) {
                clearButton(onClearPage)
                clearButton(onClearAll, label: "all")
            }

            Spacer()

            navButton(action: onToggleAnnotations, icon: "checkmark", label: "Done")
        }
        .padding(.vertical, 4)
    }

    private var visualizationControls: some View {
        HStack(spacing: 0) {
            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    onToggleAnnotations()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "pencil")
                        .font(.title3)
                    Text("Annotate")
                        .font(.subheadline)
                }
                .foregroundColor(.orange)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func toolButton(_ tool: AnnotationTool, _ symbol: String, label: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                onToolChange(tool)
            }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: symbol)
                    .font(.title3)
                    .foregroundColor(currentTool == tool ? .primary : .secondary)
                    .padding(8)
                    .background(
                        currentTool == tool
                            ? Color.primary.opacity(0.15)
                            : Color.clear
                    )
                    .clipShape(Circle())

                Text(label.uppercased())
                    .font(.caption2)
                    .foregroundColor(currentTool == tool ? .primary : .secondary)
            }
        }
    }

    private var colorPicker: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                onColorChange()
            }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: currentColor.symbolName)
                    .font(.title3)
                    .foregroundColor(currentColor.swiftUIColor)
                    .padding(8)
                    .background(Color.primary.opacity(0.1))
                    .clipShape(Circle())

                Text(currentColor.name.uppercased())
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var pageIndicator: some View {
        Text("\(currentPageIndex)")
            .font(.caption.monospaced())
            .foregroundColor(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.primary.opacity(0.1))
            .clipShape(Capsule())
    }

    @ViewBuilder
    private func navButton(action: @escaping () -> Void, icon: String, label: String) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.title3)
                    .padding(8)
                    .background(Color.primary.opacity(0.1))
                    .clipShape(Circle())

                Text(label.uppercased())
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private func clearButton(_ action: @escaping () -> Void, label: String = "page") -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: "trash")
                    .font(.title3)
                    .padding(8)
                    .background(Color.red.opacity(0.12))
                    .clipShape(Circle())

                Text("Clear \(label.uppercased())")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct RoundedCorners: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#endif
