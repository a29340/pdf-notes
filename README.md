# PDFNotes

A cross-platform Apple app (iOS + macOS) for reading PDFs with Apple Pencil annotation support on iPad and cloud-synced document storage via iCloud. Built with SwiftUI, PDFKit, PencilKit using the modern `@main` lifecycle (no storyboard).

## Features

- **iCloud document library** — PDFs stored in app's iCloud container; automatically synced across all devices:
  - Home screen lists all stored PDFs sorted alphabetically
  - Import PDFs from Files, iCloud Drive, Mail, etc. via system picker
  - Swipe-to-delete removes PDF (and annotations) from iCloud
- **PDF viewer** — single-page display powered by PDFKit with zoom in/out, reset zoom, and page navigation
- **Table of contents** — extracts the PDF outline (bookmarks), displays it as a hierarchical sidebar:
  - Nested structure via SwiftUI `DisclosureGroup`
  - Tap any entry to jump to its destination page
  - iPad/macOS: persistent `NavigationSplitView` sidebar; iPhone: sheet presented from button overlay
- **Apple Pencil annotations** (iOS only) — overlay a `PKCanvasView` on each PDF page using PencilKit:
  - Pen, highlighter, and eraser tools
  - Five ink colors (black, blue, red, green, yellow) cycled by tapping the color swatch
  - Canvas frame precisely aligned to each PDF page via `pdfViewVisibleRect(from:)` coordinate mapping
  - Annotation mode toggled on/off; PDF gestures disabled while drawing
- **Annotation persistence** — drawings saved per-page as `.drawing` files inside iCloud Documents:
  - File structure: `/Documents/{pdf_name}/annotations/page_{index}.drawing`
  - Serialized with `NSKeyedArchiver` (PKDrawing conforms to `NSSecureCoding`)
  - Dirty-tracking ensures only changed pages hit disk after each stroke, page switch, or exit
  - Annotations sync across devices via iCloud alongside the PDF
- **macOS support** — standard PDF viewing with zoom controls and outline sidebar (PencilKit is iOS-only)

## Architecture

```
PDFNotes/
├── PDFNotesApp.swift              # @main entry, Scene setup, macOS menu commands
├── Info.plist                     # iOS file access entitlements
├── Assets.xcassets/               # AccentColor, AppIcon
├── Models/
│   ├── Document.swift             # Value type: URL + display name
│   ├── AnnotationStore.swift      # PKDrawing dict, dirty set, per-page file I/O
│   ├── CloudDocumentManager.swift # iCloud ubiquity container: init, list, copy, delete
│   └── OutlineItem.swift          # Recursive tree model from PDFDocument.outlineItems
├── ViewModels/
│   └── DocumentStore.swift        # ObservableObject: cloud docs, loading, annotations, outline
└── Views/
    ├── ContentView.swift          # Router + NavigationSplitView; platform-specific branches
    ├── FileBrowserView.swift      # iCloud doc list + import picker (iOS UIDocumentPicker / macOS NSOpenPanel)
    ├── OutlineSidebarView.swift   # Hierarchical List sidebar with page-number badges
    ├── PDFViewRepresentable.swift # UIViewRepresentable (iOS) / NSViewRepresentable (macOS) for PDFKit + PencilKit
    └── AnnotationToolbar.swift    # Two-row bottom toolbar: tools, colors, nav, zoom, clear (iOS only)
```

Key design patterns:

- **MVVM** — `Document`/`OutlineItem`/`AnnotationStore` (models), `CloudDocumentManager` (iCloud service), `DocumentStore` (view model), SwiftUI views
- **Conditional compilation** — `#if os(iOS)` / `#if os(macOS)` keeps platform-specific code in shared files
- **Coordinator pattern** — UIKit bridging via `UIViewRepresentable.Coordinator`; implements `PKCanvasViewDelegate` to save drawings after each stroke

## Requirements

- Xcode 15+ (Swift 5.9+)
- iOS 16+ or macOS 13+ deployment target
- Apple Pencil-compatible iPad for annotation features
- **Active Apple Developer account with iCloud Containers capability enabled**

## Setting Up iCloud

Before building, you must configure iCloud in your Apple Developer account:

1. Go to [Apple Developer Portal](https://developer.apple.com/account) → Certificates, Identifiers & Profiles
2. Find your app's bundle ID (e.g., `com.pdfnotes.app`) and edit it
3. Enable **iCloud** capability and add a new container with identifier `iCloud.com.pdfnotes.app`
4. Save the changes — Xcode will regenerate provisioning profiles on next build

If using a custom bundle ID, update `Bundle.main.bundleIdentifier` fallback in `DocumentStore.init()` to match your iCloud container's base name.

## Building the Project

### Option A: Create an Xcode project manually

1. Open Xcode → **File > New > Project** → **iOS App**
2. Name it `PDFNotes`, interface **SwiftUI**, lifecycle **SwiftUI App**, language **Swift**
3. Set deployment target to **iOS 16.0+**
4. Add a **macOS target**:
   - File > New > Target > macOS App → name it `PDFNotesMac`
   - Set deployment target to **macOS 13.0+**
5. Drag the `PDFNotes/` folder from this repository into both targets in Xcode project navigator
6. Ensure all `.swift` files are added to both targets (check "Add to targets")
7. Enable required capabilities for each target:
   - Project > target > **Signing & Capabilities** → **+ Capability** → **iCloud**
     - Check **iCloud Documents**
     - Add container `iCloud.com.pdfnotes.app` (must match your Developer Portal setup)
8. For the iOS target, verify **PencilKit** is linked:
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
            ]),
            capabilities: [.iCloud(cloudKit: nil, documents: ["iCloud.com.pdfnotes.app"], keyvalueStorage: false)]
        )
    ]
)
```

## Deploying to an iPad (Test Device)

### Prerequisites

- Active Apple Developer account with iCloud Containers configured (see above)
- Your iPad registered in **Xcode > Settings > Accounts** (click your team → Manage Devices → + to add the iPad)
- A Lightning/USB-C cable connecting Mac to iPad

### Steps

1. **Connect the iPad** via USB and trust the computer on the device
2. **Select the target device**:
   - In Xcode, click the scheme dropdown (top-left toolbar)
   - Choose your iPad from the list of attached devices
3. **Verify signing & capabilities**:
   - Project > PDFNotes target > Signing & Capabilities
   - Check **Automatically manage signing**
   - Select your team
   - Verify iCloud capability shows ✓ with correct container
4. **Build and run**: press `⌘R` or Product > Run
5. **Test features**:
   - On the home screen, tap "Import PDF" to pick a file from Files/iCloud Drive/Mail/etc.
   - The PDF is copied into iCloud Documents — appears in the doc list on all devices
   - Tap any listed PDF to open it; outline sidebar shows bookmarks if present
   - Tap the pencil icon (top-right toolbar) to enter annotation mode
   - Use Apple Pencil or finger to draw; switch tools/colors from bottom toolbar
   - Navigate between pages — drawings persist and sync via iCloud across devices

### Troubleshooting

| Issue | Fix |
|---|---|
| "No signing certificate" | Xcode > Settings > Accounts → sign in with Apple ID, ensure team is selected |
| iPad not appearing in device list | Try a different cable/port; check developer mode enabled (Settings > Privacy & Security > Developer) |
| iCloud container assertion failure | Verify provisioning profile includes your container identifier (`iCloud.com.pdfnotes.app`); clean build folder (`⇧⌘K`) |
| Cloud doc list stays empty | Ensure iCloud is signed in on device; check that at least one PDF was imported successfully |
| Outline sidebar empty | PDF must have bookmarks/outline defined; some generated or scanned PDFs lack this metadata |
| PencilKit canvas misaligned | `pdfView.autoScales = false`; canvas frame uses `pdfViewVisibleRect(from:)` which depends on magnification |
| Annotations not syncing | Verify `.drawing` files appear in iCloud Documents via Files app under the app's folder; check device has internet connectivity |

## Limitations

- Drawings stored as separate files alongside the PDF in iCloud; not embedded back into the PDF itself
- PencilKit is iOS-only; macOS build provides read-only PDF viewing with outline sidebar
- No support for exporting annotated pages to a new PDF (future enhancement)
- Outline extraction relies on `PDFDocument.outlineItems`; PDFs without bookmarks show an empty sidebar
- Conflict resolution is simple: last-write-wins (iCloud default behavior); no manual merge UI
