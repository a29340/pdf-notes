import ProjectDescription

// MARK: - Shared settings

let project = Project(
    name: "PDFNotes",
    options: .options(
        developmentRegion: "en"
    ),
    packages: [],
    settings: .settings(
        base: [
            "SWIFT_VERSION": "5.9",
            "INFOPLIST_FILE": "PDFNotes/Info.plist",
        ],
        configurations: [
            .debug(name: "Debug"),
            .release(name: "Release"),
        ]
    ),
    targets: [
        // MARK: - iOS target

        .target(
            name: "PDFNotes",
            destinations: .iOS,
            product: .app,
            productName: "PDFNotes",
            bundleId: "com.pdfnotes.app",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .extendingDefault(with: [
                "UIFileSharingEnabled": true,
                "LSSupportsOpeningDocumentsInPlace": true,
            ]),
            sources: ["PDFNotes/**/*.swift"],
            resources: [
                "PDFNotes/Assets.xcassets",
            ],
            entitlements: "PDFNotes/PDFNotes.entitlements",
            dependencies: [
                .sdk(name: "PencilKit", type: .framework),
                .sdk(name: "PDFKit", type: .framework),
            ],
        ),

        // MARK: - macOS target

        .target(
            name: "PDFNotesMac",
            destinations: .macOS,
            product: .app,
            productName: "PDFNotesMac",
            bundleId: "com.pdfnotes.app.mac",
            deploymentTargets: .macOS("13.0"),
            infoPlist: .default,
            sources: ["PDFNotes/**/*.swift"],
            resources: [
                "PDFNotes/Assets.xcassets",
            ],
            entitlements: "PDFNotes/PDFNotesMac.entitlements",
            dependencies: [
                .sdk(name: "PDFKit", type: .framework),
            ],
        ),
    ]
)