# Offline Reading and Stability Design

## Goals

This change fixes three user-visible regressions and adds durable offline topic reading:

- preserve the selected entry scope, such as today's entries or a şükela period, across every page transition;
- replace unstable loading placeholders with deterministic skeleton layouts;
- preload entry images and present them in a reliable, zoomable full-screen gallery;
- let users download normal or şükela topic entries for the first 5 pages, first 10 pages, or all pages and read them without a connection;
- audit adjacent navigation, parsing, pagination, loading, and error paths for regressions.

## Architecture

### Filter-aware topic requests

Topic navigation will use a `TopicRequest` value instead of appending strings to a raw link. The value owns the clean topic path, ordered query items, and optional page. Replacing a page modifies only the `p` item and therefore retains `day`, `a`, `period`, `author`, `keywords`, and future filters. `EntryFilter` will produce query items, and entry loading, pagination, offline downloads, and share links will all use the same request builder.

This centralizes URL behavior and removes the current difference between initial loading, filter application, and pagination. Unit tests will cover today's entries, each şükela period, search/author filters, duplicate `p` removal, percent encoding, and absolute/relative links.

### Stable skeletons

A shared skeleton row will use fixed proportions derived from available width, not random values evaluated during SwiftUI rendering. Topic, entry, search, and profile loading states will use deterministic placeholder structures with a single opacity shimmer animation. The animation changes only opacity/gradient position and never layout, preventing rows from shrinking and growing.

### Image pipeline and lightbox

An actor-backed `ImagePipeline` will normalize URLs, reuse in-flight tasks, keep decoded images in `NSCache`, and persist response data in the system URL cache. Requests will use the shared cookie store and a useful `Accept` header. Entry and profile view models will prefetch parsed image URLs after loading. `CachedRemoteImage` will expose loading, success, and retry states without blocking the main thread.

Tapping an inline image or a recognized image link opens `ImageLightboxView`. It will page through all entry images, support pinch/double-tap zoom, show progress/error UI, and always provide a visible close button. The same components will be used by entry and profile rows.

## Offline data flow

The offline feature will use a file-backed Codable repository under Application Support. This works on iOS 16 without introducing Core Data or raising the deployment target for SwiftData.

An `OfflineTopic` manifest stores the topic identity, title, source request, selected content mode, requested page limit, completed pages, total pages, timestamps, status, and error. Each downloaded page is written atomically as an `OfflineTopicPage` containing serializable entry snapshots. Images are saved in a topic-specific media directory and referenced by deterministic hashed filenames. Partial progress remains readable and resumable.

The user starts a download from the topic toolbar and chooses normal or şükela content plus 5 pages, 10 pages, or all pages. The currently loaded topic already supplies the server page count, so the downloader clamps the selection to that count and queues all selected page transfers into the single background session at once with low concurrency. This avoids repeated background relaunch/rate-limiter delays. Background `URLSession` tasks preserve network transfers while the app is suspended. Delegate callbacks update the manifest, parse completed HTML, schedule discovered images, and restore progress after relaunch. Rate limits and transient failures use bounded retries; cancellation and deletion remove pending tasks and local files.

A fifth main tab, “çevrimdışı,” lists saved and active downloads with progress, last-updated time, retry, delete, and storage size. Selecting an item opens the normal entry UI in read-only offline mode. Voting, favoriting, and other network-only actions are hidden while offline.

## Error handling and safety

- Atomic file replacement prevents corrupt manifests after termination.
- Duplicate entry IDs and image URLs are removed while preserving page order.
- “All pages” shows the resolved page count before queuing and remains cancelable.
- Downloads use at most two page requests concurrently to reduce rate-limit risk.
- A failed image does not fail its topic; the gallery retains a retry action.
- Existing offline content remains available while a refresh is in progress.
- Storage decoding failures are isolated to the affected topic and surfaced in its row.

## Testing and verification

Tests will be written before production changes for request construction, filter-preserving pagination, page-limit resolution, manifest state transitions, atomic storage round-trips, deduplication, and parser snapshots. Existing parser tests will be extended for image-link normalization and malformed HTML.

The bug audit will also inspect forced unwraps, unbounded pagination, duplicate loads, stale loading flags, invalid URLs, missing view types, and accessibility labels. XcodeGen generation and Swift parse checks will run locally. A full simulator build and XCTest run require a complete Xcode installation; the current machine only has Command Line Tools, so that final verification must be run in Xcode or CI.
