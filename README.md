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

## Assumptions

- Mock service has 12 reviews across 3 pages (5 per page). Real API would conform to `ReviewServiceProtocol` with no other changes needed.
- Image loading uses `URLSession` directly. Production would add `NSCache`.
- Sort is treated as server-side — the mock re-sorts on every fetch, matching real API behavior.
