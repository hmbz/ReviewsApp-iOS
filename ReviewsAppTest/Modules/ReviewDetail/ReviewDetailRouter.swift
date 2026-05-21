import UIKit

final class ReviewDetailRouter: ReviewDetailRouterProtocol {

    // Wires up all VIPER layers and returns the ready-to-use module
    static func createModule(with review: Review) -> UIViewController {
        let view      = ReviewDetailViewController()
        let presenter = ReviewDetailPresenter(review: review)

        // Connect layers
        view.presenter  = presenter
        presenter.view  = view

        return view
    }
}
