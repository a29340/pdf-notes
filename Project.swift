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

        Target(
            name: "PDFNotes",
            platform: .iOS,
            product: .app,
            productName: nil,
            bundleIdentifier: "com.pdfnotes.app",
            deploymentTargets: .iOS("16.0"),
            sources: ["PDFNotes/**/*.swift"],
            resources: [
                "PDFNotes/Assets.xcassets",
                "PDFNotes/Info.plist",
            ],
            dependencies: [
                .framework("PencilKit"),
                .framework("PDFKit"),
            ],
            infoPlist: .extendingDefault(with: [
                "UIFileSharingEnabled": true,
                "LSSupportsOpeningDocumentsInPlace": true,
            ]),
            entitlements: "PDFNotes/PDFNotes.entitlements",
            preBuildScripts: []
        ),

        // MARK: - macOS target

        Target(
            name: "PDFNotesMac",
            platform: .macOS,
            product: .app,
            productName: nil,
            bundleIdentifier: "com.pdfnotes.app.mac",
            deploymentTargets: .macOS("13.0"),
            sources: ["PDFNotes/**/*.swift"],
            resources: [
                "PDFNotes/Assets.xcassets",
            ],
            dependencies: [
                .framework("PDFKit"),
            ],
            infoPlist: .default,
            entitlements: "PDFNotes/PDFNotesMac.entitlements",
            preBuildScripts: []
        ),
    ]
)
