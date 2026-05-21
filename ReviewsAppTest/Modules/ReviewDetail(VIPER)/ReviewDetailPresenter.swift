import UIKit

final class ReviewDetailPresenter: ReviewDetailPresenterProtocol {

    // MARK: - VIPER

    weak var view:   ReviewDetailViewProtocol?
    weak var router: ReviewDetailRouterProtocol?

    // MARK: - Private

    private let review:     Review
    private var isExpanded = false

    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .long
        df.timeStyle = .none
        return df
    }()

    // MARK: - Init

    init(review: Review) {
        self.review = review
    }

    // MARK: - View Events

    func viewDidLoad() {
        // Build display model here — View receives ready-to-render data only
        view?.display(buildDisplayModel())
    }

    func didTapExpandCollapse() {
        isExpanded.toggle()
        view?.setExpanded(isExpanded)
    }

    func didTapUserName() {
        // Presenter owns the decision — View just reports the tap
        router?.navigateToProfile(for: review.id)
    }

    // MARK: - Private — Build Display Model
    // All business logic lives here, not in the View

    private func buildDisplayModel() -> ReviewDisplayModel {
        let filled = String(repeating: "★", count: review.rating)
        let empty  = String(repeating: "☆", count: 5 - review.rating)

        let starsColor: UIColor
        switch review.rating {
        case 4...5: starsColor = .systemYellow
        case 3:     starsColor = .systemOrange
        default:    starsColor = .systemRed
        }

        let dateText = Self.dateFormatter.string(from: review.createdAt)

        let expandedContent = """
        Reviewer : \(review.userName)
        Rating   : \(review.rating) / 5
        Date     : \(dateText)

        \(review.text)
        """

        return ReviewDisplayModel(
            name:            review.userName,
            starsText:       filled + empty,
            starsColor:      starsColor,
            dateText:        dateText,
            reviewText:      review.text,
            imageURLs:       review.imageURLs,
            expandedContent: expandedContent
        )
    }
}
