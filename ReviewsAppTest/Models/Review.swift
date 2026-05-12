import Foundation

// MARK: - Review Model

struct Review {
    let id: String
    let userName: String
    let rating: Int
    let text: String
    let imageURL: String?
    let createdAt: Date
}

// MARK: - Page Model

struct ReviewsPage {
    let items: [Review]
    let page: Int
    let hasMore: Bool
}

// MARK: - Sort Options

enum SortOption: String, CaseIterable {
    case newest        = "Newest"
    case highestRating = "Highest Rating"
}
