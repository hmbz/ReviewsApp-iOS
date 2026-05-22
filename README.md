# ReviewsAppTest

iOS take-home — product reviews screen built with UIKit, MVVM, and a protocol-based service layer.

## How to Run

1. Open `ReviewsAppTest.xcodeproj` in Xcode
2. Select any iPhone simulator (iOS 15+)
3. **Cmd + R** to build and run

No third-party dependencies. No CocoaPods or SPM required.

---

## Architecture

MVVM with a delegate pattern. The ViewController has zero business logic — it only renders state and forwards user actions to the ViewModel.

`ReviewServiceProtocol` abstracts the data layer. Swapping the mock for a real `URLSession` implementation requires no changes to the ViewController or ViewModel.

---

## Features

- Paginated reviews list — loads page 1 on open, appends next pages on scroll
- Sort by Newest or Highest Rating — changing sort resets to page 1
- Each review shows name, star rating, date, review text, and an optional image
- Full state handling: loading spinner, empty state, inline and full-screen error with retry, end-of-list footer
- Duplicate request prevention via `isLoading` guard

---

---

## Review Details Module

This module is a core part of the Review feature, built using the **VIPER** architecture. I focused on making the code not just functional, but cleaner, more efficient, and robust.

### Why this approach?

Following our last discussion, I wanted to show that I really listened to your feedback. This implementation is a step up from my previous work:

- **Growth & Code Quality** — I avoided redundant logic and focused on consolidating all constraint setups into a single, clean `setupConstraints()` function instead of scattering them across the codebase.

- **Native Efficiency** — Instead of building a custom scroll implementation for the image slider, I used the native `UICollectionView`. It handles cell recycling and memory management internally, which makes the UI much more performant.

- **Architecture (VIPER + SnapKit)** — I maintained the VIPER architecture as per your team's preference. I used SnapKit because it makes layout code more readable and easier to debug than native AutoLayout.

- **Interactor Note** — The Interactor structure is ready, but API logic hasn't been implemented yet as no endpoint was provided. It is a plug-and-play slot — once you have an API, you simply drop the service logic there, and the rest of the app does not need to know it changed.

### Key Features & Polish

- **Adaptive UI** — The screen responds to data. If there are no images, the space simply vanishes — no weird empty boxes.

- **Image Carousel** — `UICollectionView` provides a smooth, native swiping experience. Auto-scroll with a `Timer` is handled carefully to ensure there are no retain cycles or memory leaks.

- **Expandable Section** — A clean toggle animation for "Review Details." Smooth, intuitive, and hides the clutter until the user actually wants to see it.

- **Memory Safety** — Extra care has been taken with `[weak self]` and ensuring timers and loaders are cancelled in `deinit` or `prepareForReuse`. No retain cycles, no memory leaks.

- **Error Handling** — Every image cell has a built-in `errorView`. If a link is broken, the user sees a clear `exclamationmark.triangle` indicator instead of a blank space.

### Technical Details

| Detail | Value |
|--------|-------|
| Architecture | VIPER (View, Interactor, Presenter, Entity, Router) |
| Layout | Programmatic UI using SnapKit |
| Testing | Unit tests for the Presenter in `ReviewDetailPresenterTests.swift` |

I believe code is not truly finished until it is tested, so I made sure the core Presenter logic is fully covered.

---

## Assumptions

- Mock service has 12 reviews across 3 pages (5 per page). Real API would conform to `ReviewServiceProtocol` with no other changes needed.
- Image loading uses `URLSession` directly. Production would add `NSCache`.
- Sort is treated as server-side — the mock re-sorts on every fetch, matching real API behavior.
