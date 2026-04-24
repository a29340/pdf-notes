import SwiftUI

#if os(iOS)

struct AnnotationToolbar: View {
    @Binding var currentTool: AnnotationTool
    @Binding var currentColor: AnnotationColor
    @Binding var currentPageIndex: Int
    @Binding var scale: CGFloat
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
            primaryControls
            Divider()
                .background(Color.white.opacity(0.3))
            secondaryControls
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(UIColor.systemGray5))
        .clipShape(RoundedCorners(radius: 12, corners: [.topLeft, .topRight]))
    }

    private var primaryControls: some View {
        HStack(spacing: 0) {
            toolButton(.pen, "pencil")
            toolButton(.highlighter, "marker")
            toolButton(.eraser, "erase.fill")

            Spacer()

            colorPicker

            Spacer(minLength: 12)

            pageIndicator
        }
        .padding(.vertical, 4)
    }

    private var secondaryControls: some View {
        HStack(spacing: 0) {
            navButton(action: onPagePrev) {
                Image(systemName: "chevron.left")
            }
            .disabled(currentPageIndex <= 1)

            navButton(action: onPageNext) {
                Image(systemName: "chevron.right")
            }
            .disabled(currentPageIndex >= pageCount)

            Spacer()

            zoomOutButton
            zoomInButton

            Spacer()

            clearButton(onClearPage)
            clearButton(onClearAll, label: "all")

            Spacer()

            navButton(action: onToggleAnnotations) {
                Image(systemName: "hand.draw")
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func toolButton(_ tool: AnnotationTool, _ symbol: String) -> some View {
        Button {} label: {
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
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.15)) {
                onToolChange(tool)
            }
        }
    }

    private var colorPicker: some View {
        Button {} label: {
            Image(systemName: currentColor.symbolName)
                .font(.title3)
                .foregroundColor(currentColor.swiftUIColor)
                .padding(8)
                .background(Color.primary.opacity(0.1))
                .clipShape(Circle())
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.15)) {
                onColorChange()
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
    private func navButton(action: @escaping () -> Void, @ViewBuilder label: () -> some View) -> some View {
        Button {} label: {
            label()
                .font(.title3)
                .padding(8)
                .background(Color.primary.opacity(0.1))
                .clipShape(Circle())
        }
        .onTapGesture { action() }
    }

    private var zoomOutButton: some View {
        Button {} label: {
            Image(systemName: "minus.magnifyingglass")
                .font(.title3)
                .padding(8)
                .background(Color.primary.opacity(0.1))
                .clipShape(Circle())
        }
        .onTapGesture {
            scale = max(0.5, scale * 0.8)
        }
    }

    private var zoomInButton: some View {
        Button {} label: {
            Image(systemName: "plus.magnifyingglass")
                .font(.title3)
                .padding(8)
                .background(Color.primary.opacity(0.1))
                .clipShape(Circle())
        }
        .onTapGesture {
            scale = min(5.0, scale * 1.25)
        }
    }

    @ViewBuilder
    private func clearButton(_ action: @escaping () -> Void, label: String = "page") -> some View {
        Button {} label: {
            Image(systemName: "trash")
                .font(.title3)
                .padding(8)
                .background(Color.red.opacity(0.12))
                .clipShape(Circle())
        }
        .onTapGesture { action() }
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
