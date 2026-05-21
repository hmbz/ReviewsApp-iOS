import XCTest
@testable import ReviewsAppTest

// MARK: - ReviewDetailPresenter Unit Tests
//
// Architecture: VIPER (no Interactor — review data passed directly via init)
// SUT:          ReviewDetailPresenter
// Mocks:        MockReviewDetailView, MockReviewDetailRouter
//
// What is tested:
//   1. viewDidLoad  — display() called, model fields are correct
//   2. Star logic   — starsText formatting, starsColor per rating range
//   3. Expand/Collapse — toggle state flows correctly to View
//   4. Router navigation — didTapUserName passes correct userId to Router

final class ReviewDetailPresenterTests: XCTestCase {

    // MARK: - SUT & Mocks

    var sut: ReviewDetailPresenter!
    var mockView: MockReviewDetailView!
    var mockRouter: MockReviewDetailRouter!

    /// Shared stub review used across most tests
    private let stubReview = Review(
        id: "user-42",
        userName: "Bilal Khan",
        rating: 4,
        text: "Great product, highly recommended!",
        imageURLs: ["https://example.com/img1.jpg"],
        createdAt: Date()
    )

    override func setUp() {
        super.setUp()
        mockView   = MockReviewDetailView()
        mockRouter = MockReviewDetailRouter()

        sut        = ReviewDetailPresenter(review: stubReview)
        sut.view   = mockView
        sut.router = mockRouter
    }

    override func tearDown() {
        sut        = nil
        mockView   = nil
        mockRouter = nil
        super.tearDown()
    }

    // MARK: - viewDidLoad Tests

    func test_viewDidLoad_callsDisplayOnView() {
        sut.viewDidLoad()
        XCTAssertTrue(mockView.displayCalled,
                      "Presenter should call display(_:) on the View after viewDidLoad")
    }

    func test_viewDidLoad_doesNotCallDisplayBeforeViewDidLoad() {
        // display() must NOT fire before viewDidLoad is explicitly called
        XCTAssertFalse(mockView.displayCalled,
                       "display(_:) should not be called before viewDidLoad")
    }

    func test_viewDidLoad_displaysCorrectName() {
        sut.viewDidLoad()
        XCTAssertEqual(mockView.receivedModel?.name, stubReview.userName)
    }

    func test_viewDidLoad_displaysCorrectReviewText() {
        sut.viewDidLoad()
        XCTAssertEqual(mockView.receivedModel?.reviewText, stubReview.text)
    }

    func test_viewDidLoad_displaysCorrectImageURLs() {
        sut.viewDidLoad()
        XCTAssertEqual(mockView.receivedModel?.imageURLs, stubReview.imageURLs)
    }

    // MARK: - Stars Formatting Tests

    func test_starsText_fourFilledOneEmpty_forRatingFour() {
        sut.viewDidLoad()
        XCTAssertEqual(mockView.receivedModel?.starsText, "★★★★☆",
                       "Rating 4 should produce 4 filled and 1 empty star")
    }

    func test_starsText_fiveFilledZeroEmpty_forRatingFive() {
        let review = makeReview(rating: 5)
        buildSUT(review: review)
        sut.viewDidLoad()
        XCTAssertEqual(mockView.receivedModel?.starsText, "★★★★★")
    }

    func test_starsText_oneFilledFourEmpty_forRatingOne() {
        let review = makeReview(rating: 1)
        buildSUT(review: review)
        sut.viewDidLoad()
        XCTAssertEqual(mockView.receivedModel?.starsText, "★☆☆☆☆")
    }

    // MARK: - Stars Color Tests

    func test_starsColor_isYellow_forRatingFour() {
        sut.viewDidLoad()
        XCTAssertEqual(mockView.receivedModel?.starsColor, .systemYellow,
                       "Rating 4–5 should produce systemYellow")
    }

    func test_starsColor_isYellow_forRatingFive() {
        buildSUT(review: makeReview(rating: 5))
        sut.viewDidLoad()
        XCTAssertEqual(mockView.receivedModel?.starsColor, .systemYellow)
    }

    func test_starsColor_isOrange_forRatingThree() {
        buildSUT(review: makeReview(rating: 3))
        sut.viewDidLoad()
        XCTAssertEqual(mockView.receivedModel?.starsColor, .systemOrange,
                       "Rating 3 should produce systemOrange")
    }

    func test_starsColor_isRed_forRatingTwo() {
        buildSUT(review: makeReview(rating: 2))
        sut.viewDidLoad()
        XCTAssertEqual(mockView.receivedModel?.starsColor, .systemRed,
                       "Rating 1–2 should produce systemRed")
    }

    func test_starsColor_isRed_forRatingOne() {
        buildSUT(review: makeReview(rating: 1))
        sut.viewDidLoad()
        XCTAssertEqual(mockView.receivedModel?.starsColor, .systemRed)
    }

    // MARK: - Expand / Collapse Tests

    func test_didTapExpandCollapse_firstTap_expandsView() {
        sut.didTapExpandCollapse()
        XCTAssertTrue(mockView.isExpanded, "First tap should expand")
    }

    func test_didTapExpandCollapse_secondTap_collapsesView() {
        sut.didTapExpandCollapse()
        sut.didTapExpandCollapse()
        XCTAssertFalse(mockView.isExpanded, "Second tap should collapse")
    }

    func test_didTapExpandCollapse_callsSetExpandedOnView() {
        sut.didTapExpandCollapse()
        XCTAssertTrue(mockView.setExpandedCalled,
                      "Presenter should call setExpanded(_:) on the View")
    }

    func test_didTapExpandCollapse_multipleToggles_stateIsConsistent() {
        // 5 taps — odd number → should end up expanded
        for _ in 1...5 { sut.didTapExpandCollapse() }
        XCTAssertTrue(mockView.isExpanded, "Odd number of taps should leave view expanded")
    }

    // MARK: - Router Navigation Tests

    func test_didTapUserName_callsRouterNavigateToProfile() {
        sut.didTapUserName()
        XCTAssertTrue(mockRouter.navigateToProfileCalled,
                      "Presenter should tell Router to navigate to profile on userName tap")
    }

    func test_didTapUserName_passesCorrectUserId() {
        sut.didTapUserName()
        XCTAssertEqual(mockRouter.receivedUserId, stubReview.id,
                       "Router should receive the review's id as userId")
    }

    func test_didTapUserName_withoutRouter_doesNotCrash() {
        sut.router = nil   // router deallocated
        XCTAssertNoThrow(sut.didTapUserName(), "Presenter should handle nil router safely")
    }
}

// MARK: - Helpers

private extension ReviewDetailPresenterTests {

    /// Creates a minimal Review with a specific rating, everything else is default.
    func makeReview(rating: Int) -> Review {
        Review(id: "test-id", userName: "Tester", rating: rating,
               text: "Some text", imageURLs: [], createdAt: Date())
    }

    /// Re-builds SUT with a different review (keeps same mocks).
    func buildSUT(review: Review) {
        sut        = ReviewDetailPresenter(review: review)
        sut.view   = mockView
        sut.router = mockRouter
    }
}

// MARK: - MockReviewDetailView

final class MockReviewDetailView: ReviewDetailViewProtocol {
    var displayCalled     = false
    var setExpandedCalled = false
    var isExpanded        = false
    var receivedModel:    ReviewDisplayModel?

    func display(_ model: ReviewDisplayModel) {
        displayCalled  = true
        receivedModel  = model
    }

    func setExpanded(_ expanded: Bool) {
        setExpandedCalled = true
        isExpanded        = expanded
    }
}

// MARK: - MockReviewDetailRouter

final class MockReviewDetailRouter: ReviewDetailRouterProtocol {
    var navigateToProfileCalled = false
    var receivedUserId: String?

    // Required by protocol — not exercised in Presenter tests
    static func createModule(with review: Review) -> UIViewController { UIViewController() }

    func navigateToProfile(for userId: String) {
        navigateToProfileCalled = true
        receivedUserId          = userId
    }
}
