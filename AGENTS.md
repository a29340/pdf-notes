# PDFNotes — Agent Instructions

## Project at a Glance
Cross-platform Apple app (iOS + macOS) for reading PDFs with Apple Pencil annotations on iPad. SwiftUI + PDFKit + PencilKit. MVVM architecture, no storyboard.

## Build & Run
- **Regenerate project**: `tuist generate` then `open PDFNotes.xcworkspace`. Always run this after adding/removing files or changing `Project.swift`.
- **Two schemes in Xcode**: `PDFNotes` (iOS) and `PDFNotesMac` (macOS). Select the correct scheme before building.
- **Build/Run**: Standard Xcode `⌘R`. No CLI build or test commands exist.
- **No tests** — the repo has zero test targets. Don't assume a test runner exists.

## Critical Architecture Gotchas
- **Shared sources, conditional compilation**: Both targets compile from `PDFNotes/**`. Files use `#if os(iOS)` / `#if os(macOS)` to branch platform-specific code. Any edit must account for both platforms.
- **PencilKit is iOS-only**: Imported with `#if os(iOS)`. Never reference PencilKit types outside that guard.
- **`PDFViewRepresentable.swift`** contains two separate structs: `UIViewRepresentable` (iOS, with PencilKit canvas overlay) and `NSViewRepresentable` (macOS, PDFView only). They live in the same file behind conditional compilation.
- **Central state**: `DocumentStore` (`ViewModels/`) is the single `@EnvironmentObject` flowing through the app. All views read/write through it.

## Annotation Persistence
Drawings saved per-page as `.drawing` files: `/Documents/{pdf_name}/annotations/page_{index}.drawing`. Serialized via `NSKeyedArchiver` (PKDrawing conforms to `NSSecureCoding`). Dirty-tracking saves only changed pages. An agent modifying annotation logic must preserve this file structure.

## Info.plist Entitlements
`UIFileSharingEnabled`, `LSSupportsOpeningDocumentsInPlace`, and custom PDF UTType declaration are in `PDFNotes/Info.plist`. Changes here affect file picker behavior and Files app visibility.

## Build Artifacts
`.gitignore` excludes `build/` (Xcode build output) and `Derived/` (Tuist generated plists).

## Tuist Manifest
`Project.swift` defines both targets. Both use `sources: ["PDFNotes/**"]` with no external dependencies. Adding a new dependency or source group requires editing this file followed by `tuist generate`.
