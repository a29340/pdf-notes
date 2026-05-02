import SwiftUI

#if os(iOS)

struct AnnotationToolbar: View {
    @Binding var currentPageIndex: Int
    var pageCount: Int
    var onClearPage: () -> Void
    var onClearAll: () -> Void
    var onPagePrev: () -> Void
    var onPageNext: () -> Void
    var onCloseDocument: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            navButton(action: onPagePrev, icon: "chevron.left", label: "Prev")
                .disabled(currentPageIndex <= 1)

            Spacer()

            pageIndicator

            Spacer(minLength: 8)

            clearButton(onClearPage)
            clearButton(onClearAll, label: "all")

            Spacer(minLength: 8)

            closeButton(onCloseDocument)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(UIColor.systemGray5))
        .clipShape(RoundedCorners(radius: 12, corners: [.topLeft, .topRight]))
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

    @ViewBuilder
    private func closeButton(_ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .padding(8)
                    .background(Color.primary.opacity(0.1))
                    .clipShape(Circle())

                Text("Close")
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
