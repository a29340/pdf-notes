import SwiftUI

#if os(iOS)

struct FileBrowserView: View {
    @EnvironmentObject var store: DocumentStore

    var body: some View {
        DocumentPickerRepresentable()
            .onChange(of: store.selectedDocument) { oldValue, newValue in
                _ = oldValue
                _ = newValue
            }
    }
}

struct DocumentPickerRepresentable: UIViewRepresentable {
    @EnvironmentObject var store: DocumentStore

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .systemBackground
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard store.selectedDocument == nil else { return }
        
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
            guard let sourceURL = urls.first else { return }

            let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            var destinationURL = documentsDir.appendingPathComponent(sourceURL.lastPathComponent)
            var counter = 1

            while FileManager.default.fileExists(atPath: destinationURL.path) {
                let name = sourceURL.deletingPathExtension().lastPathComponent
                let ext = sourceURL.pathExtension
                destinationURL = documentsDir.appendingPathComponent("\(name) (\(counter)).\(ext)")
                counter += 1
            }

            do {
                try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
                parent.store.loadDocument(at: destinationURL)
            } catch {
                parent.store.errorMessage = "Unable to import the PDF file."
            }
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
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("Select a PDF to open")
                .font(.title2)

            Button("Browse Files") {
                showOpenPanel = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            if let message = store.errorMessage {
                Text(message)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: showOpenPanel) { newValue in
            if newValue {
                NSApp.activate(ignoringOtherApps: true)
                presentOpenPanel()
            }
        }
    }

    private func presentOpenPanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        panel.begin { response in
            showOpenPanel = false

            if response == .OK, let url = panel.url {
                store.loadDocument(at: url)
            }
        }
    }
}

#endif
