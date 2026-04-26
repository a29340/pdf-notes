import SwiftUI

#if os(iOS)

struct FileBrowserView: View {
    @EnvironmentObject var store: DocumentStore

    var body: some View {
        VStack(spacing: 0) {
            if !store.cloudDocuments.isEmpty {
                documentList
            } else {
                emptyState
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            importButton
                .padding(.bottom, 12)
        }
    }

    private var documentList: some View {
        List(store.cloudDocuments) { doc in
            Button {
                HStack(spacing: 12) {
                    Image(systemName: "doc")
                        .font(.title3)
                        .foregroundColor(.blue)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(doc.name)
                            .font(.body)
                        if isCloudURL(doc.url) {
                            Image(systemName: "icloud.fill")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }

                    Spacer()
                }
            } label: { }
            .buttonStyle(.plain)
            .onTapGesture { store.loadFromCloud(doc) }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("No PDFs in iCloud")
                .font(.title2)
                .foregroundColor(.secondary)

            Text("Import a PDF to get started")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var importButton: some View {
        DocumentPickerRepresentable()
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.blue.opacity(0.12))
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
    }

    private func isCloudURL(_ url: URL) -> Bool {
        return url.absoluteString.contains("mobile~docs") ||
               url.absoluteString.contains("ubiquity")
    }

    #if os(iOS)
    private func deleteDocuments(at offsets: IndexSet) {
        for index in offsets {
            guard index < store.cloudDocuments.count else { continue }
            let doc = store.cloudDocuments[index]
            if !doc.name.lowercased().contains(store.selectedDocument?.name.lowercased() ?? "") ||
               store.selectedDocument == nil {
                store.deleteFromCloud(doc)
            }
        }
    }
    #endif
}

struct DocumentPickerRepresentable: UIViewRepresentable {
    @EnvironmentObject var store: DocumentStore

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootVC = windowScene.windows.first?.rootViewController else { return }

            let picker = UIDocumentPickerViewController(
                forOpeningContentTypes: [.pdf],
                asCopy: true
            )
            picker.delegate = context.coordinator
            rootVC.present(picker, animated: true)
        }
    }
}

extension DocumentPickerRepresentable {
    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentPickerRepresentable

        init(_ parent: DocumentPickerRepresentable) {
            self.parent = parent
        }

        func documentPicker(
            _ controller: UIDocumentPickerViewController,
            didPickDocumentsAt urls: [URL]
        ) {
            guard let url = urls.first else { return }
            parent.store.importToCloud(from: url, overwrite: true)
        }

        func documentPickerWasCancelled(
            _ controller: UIDocumentPickerViewController
        ) {}
    }
}

#endif

#if os(macOS)

struct FileBrowserView: View {
    @EnvironmentObject var store: DocumentStore
    @State private var showOpenPanel = false

    var body: some View {
        VStack(spacing: 0) {
            if !store.cloudDocuments.isEmpty {
                documentListMac
            } else {
                emptyStateMac
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Divider()

            HStack {
                Button("Import PDF") {
                    showOpenPanel = true
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .onChange(of: showOpenPanel) { newValue in
            if newValue {
                NSApp.activate(ignoringOtherApps: true)
                presentOpenPanel()
            }
        }
    }

    private var documentListMac: some View {
        List(store.cloudDocuments) { doc in
            Button {
                HStack(spacing: 12) {
                    Image(systemName: "doc")
                        .font(.title3)
                        .foregroundColor(.blue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(doc.name)
                            .font(.body)
                        if isCloudURL(doc.url) {
                            Label("iCloud", systemImage: "icloud.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }

                    Spacer()
                }
            } label: { }
            .buttonStyle(.plain)
            .onTapGesture { store.loadFromCloud(doc) }
        }
        .listStyle(.sidebar)
    }

    private var emptyStateMac: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("No PDFs in iCloud")
                .font(.title2)
                .foregroundColor(.secondary)

            Text("Import a PDF to get started")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func isCloudURL(_ url: URL) -> Bool {
        return url.absoluteString.contains("mobile~docs") ||
               url.absoluteString.contains("ubiquity")
    }

    private func presentOpenPanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        panel.begin { response in
            showOpenPanel = false

            if response == .OK, let url = panel.url {
                store.importToCloud(from: url, overwrite: true)
            }
        }
    }
}

#endif
