import ProjectDescription

let project = Project(
    name: "PDFNotes",
    options: .options(automaticSchemesOptions: .disabled),
    settings: .settings(
        base: [
            "SWIFT_VERSION": "5.9",
        ],
        configurations: [
            .debug(name: "Debug"),
            .release(name: "Release"),
        ]
    ),
    targets: [
        // MARK: - iOS Target
        .target(
            name: "PDFNotes",
            platform: .iOS,
            product: .app,
            productName: "PDFNotes",
            bundleIdentifier: "com.pdfnotes.app",
            deploymentTargets: .iOS("16.0"),
            sources: [
                "PDFNotes/**/*.swift",
            ],
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
            ])
        ),

        // MARK: - macOS Target
        .target(
            name: "PDFNotesMac",
            platform: .macOS,
            product: .app,
            productName: "PDFNotes",
            bundleIdentifier: "com.pdfnotes.app.mac",
            deploymentTargets: .macOS("13.0"),
            sources: [
                "PDFNotes/**/*.swift",
            ],
            resources: [
                "PDFNotes/Assets.xcassets",
            ],
            dependencies: [
                .framework("PDFKit"),
            ]
        ),
    ],
    schemes: [
        // iOS scheme
        .scheme(
            name: "PDFNotes",
            buildAction: .targetActions([
                .targetAction(targetName: "PDFNotes"),
            ]),
            runAction: .run(
                executable: "PDFNotes",
                launchArguments: [
                    .launchArgument(name: "-NSDocumentRevisionsDebugMode", isEnabled: false),
                ]
            ),
            testAction: .targets([]),
            profileAction: .export(destination: .iPhone)
        ),

        // macOS scheme
        .scheme(
            name: "PDFNotesMac",
            buildAction: .targetActions([
                .targetAction(targetName: "PDFNotesMac"),
            ]),
            runAction: .run(executable: "PDFNotesMac"),
            testAction: .targets([])
        ),
    ]
)
