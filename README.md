# PDFNotes

A cross-platform Apple app (iOS + macOS) for reading PDFs with Apple Pencil annotation support on iPad. Built with SwiftUI, PDFKit, and PencilKit using the modern `@main` lifecycle (no storyboard).

## Features

- **File browser** — pick a PDF from local files (`UIDocumentPickerViewController` on iOS, `NSOpenPanel` on macOS)
- **PDF viewer** — single-page display powered by PDFKit with zoom in/out, reset zoom, and page navigation
- **Apple Pencil annotations** (iOS only) — overlay a `PKCanvasView` on each PDF page using PencilKit:
  - Pen, highlighter, and eraser tools
  - Five ink colors (black, blue, red, green, yellow) cycled by tapping the color swatch
  - Per-page drawings stored in memory (`[Int: PKDrawing]`)
  - Canvas frame precisely aligned to each PDF page via `pdfViewVisibleRect(from:)` coordinate mapping
  - Annotation mode toggled on/off; PDF gestures disabled while drawing
- **macOS support** — standard PDF viewing with zoom controls (PencilKit is iOS-only)

## Architecture

```
PDFNotes/
├── PDFNotesApp.swift              # @main entry, Scene setup, macOS menu commands
├── Info.plist                     # iOS file access entitlements
├── Assets.xcassets/               # AccentColor, AppIcon
├── Models/
│   ├── Document.swift             # Value type: URL + display name
│   └── AnnotationStore.swift      # Per-page PKDrawing dict, tool/color enums
├── ViewModels/
│   └── DocumentStore.swift        # ObservableObject: PDF loading, annotation state, page navigation
└── Views/
    ├── ContentView.swift          # Router: file browser or PDF viewer; platform-specific branches
    ├── FileBrowserView.swift      # iOS UIDocumentPicker / macOS NSOpenPanel wrappers
    ├── PDFViewRepresentable.swift # UIViewRepresentable (iOS) / NSViewRepresentable (macOS) for PDFKit
    └── AnnotationToolbar.swift    # Two-row bottom toolbar: tools, colors, nav, zoom, clear (iOS only)
```

Key design patterns:

- **MVVM** — `Document` (model), `DocumentStore` (view model), SwiftUI views
- **Conditional compilation** — `#if os(iOS)` / `#if os(macOS)` keeps platform-specific code in shared files
- **Coordinator pattern** — UIKit bridging via `UIViewRepresentable.Coordinator` for PDFView + PKCanvasView lifecycle

## Requirements

- Xcode 15+ (Swift 5.9+)
- iOS 16+ or macOS 13+ deployment target
- Apple Pencil-compatible iPad for annotation features

## Building the Project

### Option A: Create an Xcode project manually

1. Open Xcode → **File > New > Project** → **iOS App**
2. Name it `PDFNotes`, interface **SwiftUI**, lifecycle **SwiftUI App**, language **Swift**
3. Set deployment target to **iOS 16.0+**
4. In the project settings, add a **macOS target**:
   - File > New > Target > macOS App → name it `PDFNotesMac`
   - Set deployment target to **macOS 13.0+**
5. Drag the `PDFNotes/` folder from this repository into both targets in the Xcode project navigator
6. Ensure all `.swift` files are added to both targets (check "Add to targets" in the dialog)
7. For the iOS target, verify **PencilKit** is linked:
   - Project > PDFNotes target > General > Frameworks, Libraries, and Embedded Content
   - Add `PencilKit.framework` if not present

### Option B: Generate with Tuist (recommended)

```bash
brew install tuist

# From this repository root:
tuist generate
open PDFNotes.xcworkspace
```

This requires a `Project.swift` manifest. A minimal one:

```swift
import ProjectDescription

let project = Project(
    name: "PDFNotes",
    targets: [
        Target(
            name: "PDFNotes",
            platform: .iOS,
            product: .app,
            productName: "PDFNotes",
            sources: ["PDFNotes/**/*.swift"],
            resources: ["PDFNotes/Assets.xcassets", "PDFNotes/Info.plist"],
            dependencies: [.framework("PencilKit"), .framework("PDFKit")],
            infoPlist: .extendingDefault(with: [
                "UIFileSharingEnabled": true,
                "LSSupportsOpeningDocumentsInPlace": true,
            ])
        )
    ]
)
```

## Deploying to an iPad (Test Device)

### Prerequisites

- Active Apple Developer account (free tier supports debugging on one device at a time; paid for ad hoc/production distribution)
- Your iPad registered in **Xcode > Settings > Accounts** (click your team → Manage Devices → + to add the iPad)
- A Lightning/USB-C cable connecting Mac to iPad

### Steps

1. **Connect the iPad** via USB and trust the computer on the device
2. **Select the target device**:
   - In Xcode, click the scheme dropdown (top-left toolbar)
   - Choose your iPad from the list of attached devices
3. **Verify signing**:
   - Project > PDFNotes target > Signing & Capabilities
   - Check **Automatically manage signing**
   - Select your team
4. **Build and run**: press `⌘R` or Product > Run
   - Xcode compiles, signs with a development certificate, installs the app, and launches it on the iPad
5. **Test annotations**:
   - Tap the pencil icon (top-right toolbar) to enter annotation mode
   - Use Apple Pencil or finger to draw on any page
   - Switch tools/colors from the bottom toolbar
   - Navigate between pages — drawings persist per page

### Troubleshooting

| Issue | Fix |
|---|---|
| "No signing certificate" | Xcode > Settings > Accounts → sign in with Apple ID, ensure team is selected |
| iPad not appearing in device list | Try a different cable/port; restart iTunes/Music app; check that developer mode is enabled on iPad (Settings > Privacy & Security > Developer) |
| PencilKit canvas misaligned | Ensure `pdfView.autoScales = false`; the canvas frame uses `pdfViewVisibleRect(from:)` which depends on PDFView's current magnification |
| Annotations don't persist across pages | Verify `synchronizeCanvas` is called on page change and saves drawing before switching |

## Limitations

- Drawings are kept in memory only; closing/reopening a document loses annotations
- PencilKit is iOS-only; macOS build provides read-only PDF viewing
- No support for saving annotated PDFs to disk (future enhancement)
