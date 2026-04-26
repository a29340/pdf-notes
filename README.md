# PDFNotes

A cross-platform Apple app (iOS + macOS) for reading PDFs with Apple Pencil annotation support on iPad. Built with SwiftUI, PDFKit, and PencilKit using the modern `@main` lifecycle (no storyboard).

## Features

- **File browser** — pick a PDF from local files (`UIDocumentPickerViewController` on iOS, `NSOpenPanel` on macOS)
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
- **Annotation persistence** — drawings saved per-page as `.drawing` files in the app's Documents directory:
  - File structure: `/Documents/{pdf_name}/annotations/page_{index}.drawing`
  - Serialized with `NSKeyedArchiver` (PKDrawing conforms to `NSSecureCoding`)
  - Dirty-tracking ensures only changed pages hit disk after each stroke, page switch, or exit
  - Automatically loaded when reopening the same PDF; survives app relaunch
- **macOS support** — standard PDF viewing with zoom controls and outline sidebar (PencilKit is iOS-only)

## Architecture

```
PDFNotes/
├── PDFNotesApp.swift              # @main entry, Scene setup, macOS menu commands
├── Info.plist                     # iOS file access entitlements
├── Assets.xcassets/               # AccentColor, AppIcon
├── Models/
│   ├── Document.swift             # Value type: URL + display name
│   ├── AnnotationStore.swift      # PKDrawing dict, dirty set, file I/O (save/load per page)
│   └── OutlineItem.swift          # Recursive tree model extracted from PDFDocument.outlineItems
├── ViewModels/
│   └── DocumentStore.swift        # ObservableObject: PDF loading, annotation state, outline, navigation
└── Views/
    ├── ContentView.swift          # Router + NavigationSplitView; platform-specific branches
    ├── FileBrowserView.swift      # iOS UIDocumentPicker / macOS NSOpenPanel wrappers
    ├── OutlineSidebarView.swift   # Hierarchical List sidebar with page-number badges
    ├── PDFViewRepresentable.swift # UIViewRepresentable (iOS) / NSViewRepresentable (macOS) for PDFKit + PencilKit
    └── AnnotationToolbar.swift    # Two-row bottom toolbar: tools, colors, nav, zoom, clear (iOS only)
```

Key design patterns:

- **MVVM** — `Document`/`OutlineItem`/`AnnotationStore` (models), `DocumentStore` (view model), SwiftUI views
- **Conditional compilation** — `#if os(iOS)` / `#if os(macOS)` keeps platform-specific code in shared files
- **Coordinator pattern** — UIKit bridging via `UIViewRepresentable.Coordinator`; implements `PKCanvasViewDelegate` to save drawings after each stroke

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

This repository includes a `Project.swift` manifest that defines both the iOS and macOS targets.

```bash
brew install tuist

# From this repository root:
tuist generate
open PDFNotes.xcworkspace
```

The manifest creates two schemes — select **PDFNotes** for iOS or **PDFNotesMac** for macOS from Xcode's scheme dropdown.

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
5. **Test features**:
   - Open a PDF with bookmarks to see the outline sidebar (or sheet on iPhone)
   - Tap an outline entry to jump to that page
   - Tap the pencil icon (top-right toolbar) to enter annotation mode
   - Use Apple Pencil or finger to draw; switch tools/colors from the bottom toolbar
   - Navigate between pages — drawings persist per-page and survive app relaunch

### Troubleshooting

| Issue | Fix |
|---|---|
| "No signing certificate" | Xcode > Settings > Accounts → sign in with Apple ID, ensure team is selected |
| iPad not appearing in device list | Try a different cable/port; check that developer mode is enabled (Settings > Privacy & Security > Developer) |
| Outline sidebar empty | PDF must have bookmarks/outline defined; some generated or scanned PDFs lack this metadata |
| PencilKit canvas misaligned | Ensure `pdfView.autoScales = false`; the canvas frame uses `pdfViewVisibleRect(from:)` which depends on current magnification |
| Annotations not persisting after relaunch | Verify `.drawing` files exist in app's Documents directory via Xcode device console or Files app (if UIFileSharingEnabled) |

## Limitations

- Drawings stored as separate files alongside the PDF; not embedded back into the PDF itself
- PencilKit is iOS-only; macOS build provides read-only PDF viewing with outline sidebar
- No support for exporting annotated pages to a new PDF (future enhancement)
- Outline extraction relies on `PDFDocument.outlineItems`; PDFs without bookmarks show an empty sidebar
