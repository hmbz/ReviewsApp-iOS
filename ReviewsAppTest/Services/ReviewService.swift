import Foundation

// MARK: - Protocol (abstracts real vs mock)

protocol ReviewServiceProtocol {
    func fetchReviews(page: Int, sort: SortOption, completion: @escaping (Result<ReviewsPage, Error>) -> Void)
}

// MARK: - Custom Errors

enum ReviewServiceError: LocalizedError {
    case networkFailure
    case noData

    var errorDescription: String? {
        switch self {
        case .networkFailure: return "Network request failed. Please check your connection and try again."
        case .noData:         return "No data was returned from the server."
        }
    }
}

// MARK: - Mock Service (simulates paginated async API)

final class MockReviewService: ReviewServiceProtocol {

    var shouldFail  = false
    var failOnPage: Int? = nil

    private let pageSize = 5

    // 12 sample reviews — enough for 3 pages
    private let allReviews: [Review] = {
        let base = Date()
        let day: TimeInterval = 86_400
        return [
            Review(id: "1",  userName: "Alice Johnson",  rating: 5, text: "Absolutely love this product! Best purchase I've made this year.",   imageURL: "https://picsum.photos/seed/r1/400/200",  createdAt: base),
            Review(id: "2",  userName: "Bob Smith",      rating: 4, text: "Very good quality overall. Would definitely recommend to friends.",   imageURL: nil,                                       createdAt: base - day * 1),
            Review(id: "3",  userName: "Carol White",    rating: 2, text: "Disappointed with the build quality. Expected much better for price.", imageURL: "https://picsum.photos/seed/r3/400/200",  createdAt: base - day * 2),
            Review(id: "4",  userName: "David Lee",      rating: 5, text: "Exceeded my expectations in every single way. Highly recommended!",   imageURL: nil,                                       createdAt: base - day * 3),
            Review(id: "5",  userName: "Eva Martinez",   rating: 3, text: "Decent product for the price point. Nothing too special though.",     imageURL: "https://picsum.photos/seed/r5/400/200",  createdAt: base - day * 4),
            Review(id: "6",  userName: "Frank Brown",    rating: 5, text: "Perfect! Arrived super quickly and works absolutely flawlessly.",      imageURL: nil,                                       createdAt: base - day * 5),
            Review(id: "7",  userName: "Grace Kim",      rating: 1, text: "Terrible experience. Product stopped working after just one week.",    imageURL: "https://picsum.photos/seed/r7/400/200",  createdAt: base - day * 6),
            Review(id: "8",  userName: "Henry Davis",    rating: 4, text: "Solid product overall. Had a minor packaging issue but great value.",  imageURL: nil,                                       createdAt: base - day * 7),
            Review(id: "9",  userName: "Isla Thompson",  rating: 5, text: "Incredible value for money! Will definitely be buying again soon.",   imageURL: "https://picsum.photos/seed/r9/400/200",  createdAt: base - day * 8),
            Review(id: "10", userName: "Jack Wilson",    rating: 3, text: "Average product. Does exactly what it says, nothing more nothing less.", imageURL: nil,                                     createdAt: base - day * 9),
            Review(id: "11", userName: "Karen Moore",    rating: 5, text: "Outstanding quality! Far better than all the alternatives out there.", imageURL: "https://picsum.photos/seed/r11/400/200", createdAt: base - day * 10),
            Review(id: "12", userName: "Liam Taylor",    rating: 2, text: "Not really worth the money in my opinion. Quality feels quite subpar.", imageURL: nil,                                     createdAt: base - day * 11),
        ]
    }()

    func fetchReviews(page: Int, sort: SortOption, completion: @escaping (Result<ReviewsPage, Error>) -> Void) {
        // Simulate network delay
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self else { return }

            // Simulate failure
            if self.shouldFail || self.failOnPage == page {
                completion(.failure(ReviewServiceError.networkFailure))
                return
            }

            // Sort data
            let sorted: [Review]
            switch sort {
            case .newest:
                sorted = self.allReviews.sorted { $0.createdAt > $1.createdAt }
            case .highestRating:
                sorted = self.allReviews.sorted {
                    if $0.rating != $1.rating { return $0.rating > $1.rating }
                    return $0.createdAt > $1.createdAt  // tie-break by date
                }
            }

            // Paginate
            let startIndex = (page - 1) * self.pageSize
            guard startIndex < sorted.count else {
                completion(.success(ReviewsPage(items: [], page: page, hasMore: false)))
                return
            }

            let endIndex  = min(startIndex + self.pageSize, sorted.count)
            let pageItems = Array(sorted[startIndex..<endIndex])
            let hasMore   = endIndex < sorted.count

            completion(.success(ReviewsPage(items: pageItems, page: page, hasMore: hasMore)))
        }
    }
}
