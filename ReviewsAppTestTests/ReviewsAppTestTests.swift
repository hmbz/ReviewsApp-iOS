//
//  ReviewsAppTestTests.swift
//  ReviewsAppTest
//

import XCTest
@testable import ReviewsAppTest

// MARK: - Mock Service

final class MockService: ReviewServiceProtocol {

    var shouldFail = false
    var callCount  = 0
    var pages: [Int: ReviewsPage] = [:]

    // Synchronous — no GCD, avoids double-dispatch with ViewModel's setState
    func fetchReviews(page: Int, sort: SortOption, completion: @escaping (Result<ReviewsPage, Error>) -> Void) {
        callCount += 1
        if shouldFail {
            completion(.failure(ReviewServiceError.networkFailure))
        } else {
            let result = pages[page] ?? ReviewsPage(items: [], page: page, hasMore: false)
            completion(.success(result))
        }
    }

    static func page(_ count: Int, page: Int = 1, hasMore: Bool = false) -> ReviewsPage {
        let items = (1...count).map {
            Review(id: "\($0)", userName: "User \($0)", rating: 4,
                   text: "Review text", imageURL: nil, createdAt: Date())
        }
        return ReviewsPage(items: items, page: page, hasMore: hasMore)
    }
}

// MARK: - Spy Delegate

final class Spy: ReviewsViewModelDelegate {
    var onUpdate: ((ReviewsViewModel) -> Void)?
    func viewModelDidUpdateState(_ vm: ReviewsViewModel) { onUpdate?(vm) }
}

// MARK: - Tests

final class ReviewsViewModelTests: XCTestCase {

    // Waits until the ViewModel leaves .loading state.
    // The MockService is synchronous so ViewModel state is set before this runs,
    // but the delegate call is still dispatched to main — hence the expectation.
    private func waitForState(vm: ReviewsViewModel, spy: Spy,
                              action: () -> Void = {},
                              timeout: TimeInterval = 2) {
        let exp = expectation(description: "state settled")
        var fulfilled = false
        spy.onUpdate = { vm in
            guard case .loading = vm.state else {
                if !fulfilled { fulfilled = true; exp.fulfill() }
                return
            }
        }
        action()
        wait(for: [exp], timeout: timeout)
        spy.onUpdate = nil
    }

    // MARK: Test 1 — First page loads reviews

    func test_firstPage_populatesReviews() {
        let svc = MockService()
        svc.pages[1] = MockService.page(3)
        let vm  = ReviewsViewModel(service: svc)
        let spy = Spy()
        vm.delegate = spy

        waitForState(vm: vm, spy: spy) { vm.loadFirstPage() }

        XCTAssertEqual(vm.reviews.count, 3)
        XCTAssertEqual(svc.callCount, 1)
    }

    // MARK: Test 2 — Sort change resets to page 1

    func test_sortChange_reloadsFromPageOne() {
        let svc = MockService()
        svc.pages[1] = MockService.page(3)
        let vm  = ReviewsViewModel(service: svc)
        let spy = Spy()
        vm.delegate = spy

        waitForState(vm: vm, spy: spy) { vm.loadFirstPage() }
        waitForState(vm: vm, spy: spy) { vm.changeSort(to: .highestRating) }

        XCTAssertEqual(svc.callCount, 2)
        XCTAssertEqual(vm.reviews.count, 3)
    }

    // MARK: Test 3 — Pagination appends next page

    func test_pagination_appendsNextPage() {
        let svc = MockService()
        svc.pages[1] = MockService.page(3, page: 1, hasMore: true)
        svc.pages[2] = MockService.page(3, page: 2, hasMore: false)
        let vm  = ReviewsViewModel(service: svc)
        let spy = Spy()
        vm.delegate = spy

        waitForState(vm: vm, spy: spy) { vm.loadFirstPage() }
        XCTAssertEqual(vm.reviews.count, 3, "after page 1")

        waitForState(vm: vm, spy: spy) { vm.loadNextPageIfNeeded() }
        XCTAssertEqual(vm.reviews.count, 6, "after page 2")
    }

    // MARK: Test 4 — No extra requests when hasMore is false

    func test_noMorePages_stopsLoading() {
        let svc = MockService()
        svc.pages[1] = MockService.page(3, hasMore: false)
        let vm  = ReviewsViewModel(service: svc)
        let spy = Spy()
        vm.delegate = spy

        waitForState(vm: vm, spy: spy) { vm.loadFirstPage() }
        vm.loadNextPageIfNeeded()   // ignored — hasMore == false

        XCTAssertEqual(svc.callCount, 1)
        XCTAssertEqual(vm.reviews.count, 3)
    }

    // MARK: Test 5 — Error then retry succeeds

    func test_error_thenRetry_loadsData() {
        let svc = MockService()
        svc.shouldFail = true
        svc.pages[1]   = MockService.page(3)
        let vm  = ReviewsViewModel(service: svc)
        let spy = Spy()
        vm.delegate = spy

        waitForState(vm: vm, spy: spy) { vm.loadFirstPage() }
        guard case .error = vm.state else { XCTFail("Expected .error"); return }

        svc.shouldFail = false
        waitForState(vm: vm, spy: spy) { vm.retry() }

        XCTAssertEqual(vm.reviews.count, 3)
    }

    // MARK: Test 6 — Rapid scroll sends only one extra request

    func test_rapidCalls_sendOnlyOneRequest() {
        let svc = MockService()
        svc.pages[1] = MockService.page(3, page: 1, hasMore: true)
        svc.pages[2] = MockService.page(3, page: 2, hasMore: false)
        let vm  = ReviewsViewModel(service: svc)
        let spy = Spy()
        vm.delegate = spy

        waitForState(vm: vm, spy: spy) { vm.loadFirstPage() }
        let before = svc.callCount  // 1

        // Three rapid calls — only the first goes through (isLoading guard)
        waitForState(vm: vm, spy: spy) {
            vm.loadNextPageIfNeeded()
            vm.loadNextPageIfNeeded()
            vm.loadNextPageIfNeeded()
        }

        XCTAssertEqual(svc.callCount, before + 1)
    }
}
