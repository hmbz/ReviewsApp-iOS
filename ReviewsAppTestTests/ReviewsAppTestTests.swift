//
//  ReviewsAppTestTests.swift
//  ReviewsAppTest
//

import XCTest
@testable import ReviewsAppTest

// MARK: - Controllable Mock Service

final class ControlledMockService: ReviewServiceProtocol {

    var shouldFail  = false
    var callCount   = 0
    var pages: [Int: ReviewsPage] = [:]

    func fetchReviews(page: Int, sort: SortOption, completion: @escaping (Result<ReviewsPage, Error>) -> Void) {
        callCount += 1
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self else { return }
            if self.shouldFail {
                completion(.failure(ReviewServiceError.networkFailure))
            } else {
                let result = self.pages[page] ?? ReviewsPage(items: [], page: page, hasMore: false)
                completion(.success(result))
            }
        }
    }

    static func makeReview(id: String, rating: Int, daysAgo: Double = 0) -> Review {
        Review(id: id, userName: "User \(id)", rating: rating,
               text: "Review text \(id)", imageURL: nil,
               createdAt: Date().addingTimeInterval(-daysAgo * 86_400))
    }
}

// MARK: - Spy Delegate

final class SpyDelegate: ReviewsViewModelDelegate {
    var onUpdate: ((ReviewsViewModel) -> Void)?
    func viewModelDidUpdateState(_ vm: ReviewsViewModel) {
        onUpdate?(vm)
    }
}

// MARK: - Tests

final class ReviewsViewModelTests: XCTestCase {

    // MARK: Test 1 — First page loads correctly

    func test_loadFirstPage_populatesReviews() {
        let service = ControlledMockService()
        let reviews = (1...3).map { ControlledMockService.makeReview(id: "\($0)", rating: 4) }
        service.pages[1] = ReviewsPage(items: reviews, page: 1, hasMore: false)

        let vm       = ReviewsViewModel(service: service)
        let exp      = expectation(description: "noMoreItems")
        let delegate = SpyDelegate()
        delegate.onUpdate = { vm in
            if case .noMoreItems = vm.state { exp.fulfill() }
        }

        vm.delegate = delegate
        vm.loadFirstPage()
        waitForExpectations(timeout: 2)

        XCTAssertEqual(vm.reviews.count, 3)
    }

    // MARK: Test 2 — Sort: highest rating triggers reload from page 1

    func test_sortHighestRating_putsBestReviewFirst() {
        let service = ControlledMockService()
        let reviews = [
            ControlledMockService.makeReview(id: "low",  rating: 1),
            ControlledMockService.makeReview(id: "high", rating: 5),
            ControlledMockService.makeReview(id: "mid",  rating: 3),
        ]
        service.pages[1] = ReviewsPage(items: reviews, page: 1, hasMore: false)

        let vm       = ReviewsViewModel(service: service)
        let exp      = expectation(description: "loaded")
        let delegate = SpyDelegate()
        var done     = false
        delegate.onUpdate = { vm in
            guard !done else { return }
            switch vm.state {
            case .noMoreItems, .loaded: done = true; exp.fulfill()
            default: break
            }
        }

        vm.delegate = delegate
        vm.loadFirstPage()
        waitForExpectations(timeout: 2)

        XCTAssertEqual(vm.reviews.count, 3)
        XCTAssertEqual(service.callCount, 1)
    }

    // MARK: Test 3 — Pagination appends page 2

    func test_pagination_appendsNextPage() {
        let service = ControlledMockService()
        let p1 = (1...3).map { ControlledMockService.makeReview(id: "\($0)",   rating: 5) }
        let p2 = (4...6).map { ControlledMockService.makeReview(id: "\($0+3)", rating: 4) }

        service.pages[1] = ReviewsPage(items: p1, page: 1, hasMore: true)
        service.pages[2] = ReviewsPage(items: p2, page: 2, hasMore: false)

        let vm       = ReviewsViewModel(service: service)
        let exp1     = expectation(description: "Page 1 loaded")
        let exp2     = expectation(description: "Page 2 loaded")
        let delegate = SpyDelegate()
        var pagesDone = 0
        delegate.onUpdate = { vm in
            if case .loading = vm.state { return }
            pagesDone += 1
            if pagesDone == 1 { exp1.fulfill() }
            if pagesDone == 2 { exp2.fulfill() }
        }

        vm.delegate = delegate
        vm.loadFirstPage()

        wait(for: [exp1], timeout: 2)
        XCTAssertEqual(vm.reviews.count, 3, "Page 1 should have 3 reviews")

        vm.loadNextPageIfNeeded()
        wait(for: [exp2], timeout: 2)
        XCTAssertEqual(vm.reviews.count, 6, "After page 2 total should be 6")
    }

    // MARK: Test 4 — Stops loading when hasMore = false

    func test_loadNextPage_stopsWhenHasMoreFalse() {
        let service = ControlledMockService()
        let reviews = (1...3).map { ControlledMockService.makeReview(id: "\($0)", rating: 5) }
        service.pages[1] = ReviewsPage(items: reviews, page: 1, hasMore: false)

        let vm       = ReviewsViewModel(service: service)
        let exp      = expectation(description: "noMoreItems")
        let delegate = SpyDelegate()
        delegate.onUpdate = { vm in
            if case .noMoreItems = vm.state { exp.fulfill() }
        }

        vm.delegate = delegate
        vm.loadFirstPage()
        waitForExpectations(timeout: 2)

        let countBefore = vm.reviews.count
        vm.loadNextPageIfNeeded()

        XCTAssertEqual(vm.reviews.count, countBefore)
        XCTAssertEqual(service.callCount, 1, "Should only call service once")
    }

    // MARK: Test 5 — Error state then retry succeeds

    func test_errorThenRetry_transitionsToLoaded() {
        let service = ControlledMockService()
        service.shouldFail = true

        let reviews = (1...3).map { ControlledMockService.makeReview(id: "\($0)", rating: 4) }
        service.pages[1] = ReviewsPage(items: reviews, page: 1, hasMore: false)

        let vm       = ReviewsViewModel(service: service)
        let expErr   = expectation(description: "Error received")
        let expOK    = expectation(description: "Loaded after retry")
        let delegate = SpyDelegate()
        var gotError = false
        var gotOK    = false
        delegate.onUpdate = { vm in
            switch vm.state {
            case .error where !gotError:
                gotError = true; expErr.fulfill()
            case .noMoreItems, .loaded where gotError && !gotOK:
                gotOK = true; expOK.fulfill()
            default:
                break
            }
        }

        vm.delegate = delegate
        vm.loadFirstPage()

        wait(for: [expErr], timeout: 2)
        if case .error = vm.state { } else { XCTFail("Expected error state") }

        service.shouldFail = false
        vm.retry()

        wait(for: [expOK], timeout: 2)
        XCTAssertEqual(vm.reviews.count, 3)
    }

    // MARK: Test 6 — No duplicate requests while loading

    func test_noDuplicateRequests_whileLoading() {
        let service = ControlledMockService()
        let reviews = (1...3).map { ControlledMockService.makeReview(id: "\($0)", rating: 5) }
        service.pages[1] = ReviewsPage(items: reviews, page: 1, hasMore: true)
        service.pages[2] = ReviewsPage(items: [],      page: 2, hasMore: false)

        let vm       = ReviewsViewModel(service: service)
        let exp      = expectation(description: "Page 1 loaded")
        let delegate = SpyDelegate()
        var done     = false
        delegate.onUpdate = { vm in
            if case .loaded = vm.state, !done { done = true; exp.fulfill() }
        }

        vm.delegate = delegate
        vm.loadFirstPage()
        waitForExpectations(timeout: 2)

        let before = service.callCount
        vm.loadNextPageIfNeeded()
        vm.loadNextPageIfNeeded()
        vm.loadNextPageIfNeeded()

        let settle = expectation(description: "settle")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { settle.fulfill() }
        waitForExpectations(timeout: 2)

        XCTAssertEqual(service.callCount, before + 1, "Only 1 additional call should be made")
    }
}
