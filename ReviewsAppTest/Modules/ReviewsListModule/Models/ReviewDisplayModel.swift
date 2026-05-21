import UIKit

// MARK: - ReviewDisplayModel
// Built by the Presenter — all data is already formatted and ready to render.
// The View receives this and only sets labels/colors — zero business logic.

struct ReviewDisplayModel {
    let name:            String
    let starsText:       String    // e.g. "★★★★☆"
    let starsColor:      UIColor   // systemYellow / systemOrange / systemRed
    let dateText:        String    // e.g. "21 May 2026"
    let reviewText:      String
    let imageURLs:       [String]
    let expandedContent: String    // pre-formatted multi-line summary
}
