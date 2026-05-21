import UIKit

// MARK: - What the Presenter does (called by View)

protocol ReviewDetailPresenterProtocol: AnyObject {
    var view: ReviewDetailViewProtocol? { get set }

    func viewDidLoad()
    func didTapExpandCollapse()
    func didTapUserName()           // View tells Presenter — Presenter decides where to go
}

// MARK: - What the View (ViewController) does (called by Presenter)
// View receives a ready-to-render DisplayModel — no formatting done in View

protocol ReviewDetailViewProtocol: AnyObject {
    func display(_ model: ReviewDisplayModel)
    func setExpanded(_ expanded: Bool)
}

// MARK: - What the Router does

protocol ReviewDetailRouterProtocol: AnyObject {
    static func createModule(with review: Review) -> UIViewController

    /// Navigate to the reviewer's profile screen.
    /// - Parameter userId: Unique identifier of the reviewer.
    /// Profile module is not yet implemented — navigation will be wired here when ready.
    func navigateToProfile(for userId: String)
}
