import ProjectDescription

let project = Project(
    name: "PDFNotes",
    targets: [
        .target(
            name: "PDFNotes",
            destinations: .iOS,
            product: .app,
            bundleId: "com.pdfnotes.app",
            infoPlist: .default,
            sources: ["PDFNotes/**"],
            dependencies: []
        ),
        .target(
            name: "PDFNotesMac",
            destinations: .macOS,
            product: .app,
            bundleId: "com.pdfnotes.app.mac",
            infoPlist: .default,
            sources: ["PDFNotes/**"],
            dependencies: []
        )
    ]
)