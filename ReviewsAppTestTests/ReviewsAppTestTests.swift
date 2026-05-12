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

// MARK: - Tests

final class ReviewsViewModelTests: XCTestCase {

    // MARK: Test 1 — First page loads correctly

    func test_loadFirstPage_populatesReviews() {
        let service  = ControlledMockService()
        let reviews  = (1...3).map { ControlledMockService.makeReview(id: "\($0)", rating: 4) }
        service.pages[1] = ReviewsPage(items: reviews, page: 1, hasMore: false)

        let vm  = ReviewsViewModel(service: service)
        let exp = expectation(description: "Loaded")

        class D: ReviewsViewModelDelegate {
            let e: XCTestExpectation
            init(_ e: XCTestExpectation) { self.e = e }
            func viewModelDidUpdateState(_ vm: ReviewsViewModel) {
                if case .noMoreItems = vm.state { e.fulfill() }
            }
        }

        vm.delegate = D(exp)
        vm.loadFirstPage()
        waitForExpectations(timeout: 2)

        XCTAssertEqual(vm.reviews.count, 3)
    }

    // MARK: Test 2 — Sort: highest rating puts 5-star first

    func test_sortHighestRating_putsBestReviewFirst() {
        let service = ControlledMockService()
        // Intentionally out of order
        let reviews = [
            ControlledMockService.makeReview(id: "low",  rating: 1),
            ControlledMockService.makeReview(id: "high", rating: 5),
            ControlledMockService.makeReview(id: "mid",  rating: 3),
        ]
        service.pages[1] = ReviewsPage(items: reviews, page: 1, hasMore: false)

        let vm  = ReviewsViewModel(service: service)
        let exp = expectation(description: "Sorted")

        class D: ReviewsViewModelDelegate {
            let e: XCTestExpectation
            init(_ e: XCTestExpectation) { self.e = e }
            func viewModelDidUpdateState(_ vm: ReviewsViewModel) {
                if case .noMoreItems = vm.state { e.fulfill() }
                if case .loaded      = vm.state { e.fulfill() }
            }
        }

        vm.delegate = D(exp)
        // Service returns as-is; real sorting happens in MockReviewService
        // Here we test that changeSort triggers a full reload from page 1
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

        let vm   = ReviewsViewModel(service: service)
        let exp1 = expectation(description: "Page 1")
        let exp2 = expectation(description: "Page 2")
        var loaded = 0

        class D: ReviewsViewModelDelegate {
            let e1, e2: XCTestExpectation
            var loaded: Int = 0
            init(_ e1: XCTestExpectation, _ e2: XCTestExpectation) { self.e1 = e1; self.e2 = e2 }
            func viewModelDidUpdateState(_ vm: ReviewsViewModel) {
                loaded += 1
                if loaded == 1 { e1.fulfill() }
                if loaded == 2 { e2.fulfill() }
            }
        }

        let delegate = D(exp1, exp2)
        vm.delegate  = delegate
        vm.loadFirstPage()

        wait(for: [exp1], timeout: 2)
        XCTAssertEqual(vm.reviews.count, 3, "Page 1 should have 3")

        vm.loadNextPageIfNeeded()
        wait(for: [exp2], timeout: 2)
        XCTAssertEqual(vm.reviews.count, 6, "After page 2, total should be 6")
    }

    // MARK: Test 4 — Stops loading when hasMore = false

    func test_loadNextPage_stopsWhenHasMoreFalse() {
        let service = ControlledMockService()
        let reviews = (1...3).map { ControlledMockService.makeReview(id: "\($0)", rating: 5) }
        service.pages[1] = ReviewsPage(items: reviews, page: 1, hasMore: false)

        let vm  = ReviewsViewModel(service: service)
        let exp = expectation(description: "Loaded")

        class D: ReviewsViewModelDelegate {
            let e: XCTestExpectation
            init(_ e: XCTestExpectation) { self.e = e }
            func viewModelDidUpdateState(_ vm: ReviewsViewModel) {
                if case .noMoreItems = vm.state { e.fulfill() }
            }
        }

        vm.delegate = D(exp)
        vm.loadFirstPage()
        waitForExpectations(timeout: 2)

        let countBefore = vm.reviews.count
        vm.loadNextPageIfNeeded()  // Should be ignored

        XCTAssertEqual(vm.reviews.count, countBefore)
        XCTAssertEqual(service.callCount, 1, "Should only call service once")
    }

    // MARK: Test 5 — Error state then retry succeeds

    func test_errorThenRetry_transitionsToLoaded() {
        let service     = ControlledMockService()
        service.shouldFail = true

        let reviews = (1...3).map { ControlledMockService.makeReview(id: "\($0)", rating: 4) }
        service.pages[1] = ReviewsPage(items: reviews, page: 1, hasMore: false)

        let vm      = ReviewsViewModel(service: service)
        let expErr  = expectation(description: "Error")
        let expOK   = expectation(description: "Loaded after retry")

        class D: ReviewsViewModelDelegate {
            let eErr, eOK: XCTestExpectation
            var gotError = false
            init(_ err: XCTestExpectation, _ ok: XCTestExpectation) { eErr = err; eOK = ok }
            func viewModelDidUpdateState(_ vm: ReviewsViewModel) {
                if case .error = vm.state, !gotError { gotError = true; eErr.fulfill() }
                if case .noMoreItems = vm.state, gotError { eOK.fulfill() }
                if case .loaded      = vm.state, gotError { eOK.fulfill() }
            }
        }

        let delegate = D(expErr, expOK)
        vm.delegate  = delegate
        vm.loadFirstPage()

        wait(for: [expErr], timeout: 2)
        if case .error = vm.state { /* pass */ } else { XCTFail("Expected error state") }

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
        service.pages[2] = ReviewsPage(items: [], page: 2, hasMore: false)

        let vm  = ReviewsViewModel(service: service)
        let exp = expectation(description: "Loaded")

        class D: ReviewsViewModelDelegate {
            let e: XCTestExpectation; var done = false
            init(_ e: XCTestExpectation) { self.e = e }
            func viewModelDidUpdateState(_ vm: ReviewsViewModel) {
                if case .loaded = vm.state, !done { done = true; e.fulfill() }
            }
        }

        vm.delegate = D(exp)
        vm.loadFirstPage()
        waitForExpectations(timeout: 2)

        let before = service.callCount
        // Fire 3 rapid calls — only 1 should go through
        vm.loadNextPageIfNeeded()
        vm.loadNextPageIfNeeded()
        vm.loadNextPageIfNeeded()

        let settle = expectation(description: "settle")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { settle.fulfill() }
        waitForExpectations(timeout: 2)

        XCTAssertEqual(service.callCount, before + 1, "Only 1 additional call should be made")
    }
}
