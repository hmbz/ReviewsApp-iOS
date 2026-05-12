import Foundation

// MARK: - Delegate

protocol ReviewsViewModelDelegate: AnyObject {
    func viewModelDidUpdateState(_ viewModel: ReviewsViewModel)
}

// MARK: - ViewModel

final class ReviewsViewModel {

    // MARK: - Public Read-Only State

    private(set) var reviews:     [Review]   = []
    private(set) var state:       ViewState  = .loading
    private(set) var currentSort: SortOption = .newest

    weak var delegate: ReviewsViewModelDelegate?

    // MARK: - Private

    private let service:    ReviewServiceProtocol
    private var currentPage = 1
    private var hasMore     = true
    private var isLoading   = false

    // MARK: - Init

    init(service: ReviewServiceProtocol = MockReviewService()) {
        self.service = service
    }

    // MARK: - Public API

    /// Call on viewDidLoad — loads page 1
    func loadFirstPage() {
        reviews     = []
        currentPage = 1
        hasMore     = true
        isLoading   = false
        fetchPage(page: 1, isRefresh: true)
    }

    /// Call when user scrolls near bottom
    func loadNextPageIfNeeded() {
        guard !isLoading, hasMore else { return }
        fetchPage(page: currentPage + 1, isRefresh: false)
    }

    /// Call when sort segment changes
    func changeSort(to sort: SortOption) {
        guard sort != currentSort else { return }
        currentSort = sort
        loadFirstPage()
    }

    /// Call on retry tap
    func retry() {
        if reviews.isEmpty {
            loadFirstPage()
        } else {
            loadNextPageIfNeeded()
        }
    }

    // MARK: - Private

    private func fetchPage(page: Int, isRefresh: Bool) {
        guard !isLoading else { return }
        isLoading = true

        if isRefresh { setState(.loading) }

        service.fetchReviews(page: page, sort: currentSort) { [weak self] result in
            guard let self else { return }
            self.isLoading = false

            switch result {
            case .success(let reviewsPage):
                if isRefresh {
                    self.reviews = reviewsPage.items
                } else {
                    self.reviews.append(contentsOf: reviewsPage.items)
                }
                self.hasMore     = reviewsPage.hasMore
                self.currentPage = reviewsPage.page

                if self.reviews.isEmpty {
                    self.setState(.empty)
                } else if !self.hasMore {
                    self.setState(.noMoreItems)
                } else {
                    self.setState(.loaded)
                }

            case .failure(let error):
                self.setState(.error(error.localizedDescription))
            }
        }
    }

    private func setState(_ newState: ViewState) {
        state = newState
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.delegate?.viewModelDidUpdateState(self)
        }
    }
}
