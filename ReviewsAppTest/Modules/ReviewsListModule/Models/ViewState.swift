import Foundation

// MARK: - View State

enum ViewState {
    case loading
    case loaded
    case error(String)
    case empty
    case noMoreItems
}
