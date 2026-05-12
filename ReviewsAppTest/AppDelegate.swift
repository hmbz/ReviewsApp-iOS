//
//  AppDelegate.swift
//  ReviewsAppTest
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)

        let reviewsVC     = ReviewsListViewController()
        let navController = UINavigationController(rootViewController: reviewsVC)
        navController.navigationBar.prefersLargeTitles = true

        window?.rootViewController = navController
        window?.makeKeyAndVisible()

        return true
    }
}
