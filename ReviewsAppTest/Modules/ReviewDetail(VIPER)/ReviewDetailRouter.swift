import UIKit

final class ReviewDetailRouter: ReviewDetailRouterProtocol {

    // Router holds a weak ref to the ViewController so it can push/present new screens
    weak var viewController: UIViewController?

    // MARK: - Module Assembly

    // Wires up all VIPER layers and returns the ready-to-use module
    static func createModule(with review: Review) -> UIViewController {
        let view      = ReviewDetailViewController()
        let presenter = ReviewDetailPresenter(review: review)
        let router    = ReviewDetailRouter()

        // Connect all VIPER layers
        view.presenter        = presenter
        presenter.view        = view
        presenter.router      = router
        router.viewController = view     // Router navigates FROM this VC

        return view
    }

    // MARK: - Navigation

    /// Navigate to the reviewer's profile.
    /// Profile module is not yet implemented — push call will be added here when ready:
    ///
    ///     let profileVC = ProfileRouter.createModule(with: userId)
    ///     viewController?.navigationController?.pushViewController(profileVC, animated: true)
    func navigateToProfile(for userId: String) {
        // TODO: Replace with ProfileRouter.createModule(with: userId) when Profile module is built
        print("[Router] navigateToProfile called for userId: \(userId)")
    }
}
