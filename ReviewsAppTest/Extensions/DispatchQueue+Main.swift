import Foundation

extension DispatchQueue {

    /// Shorthand for DispatchQueue.main.async { }
    /// Use this everywhere instead of writing the full queue call each time
    static func onMain(_ block: @escaping () -> Void) {
        DispatchQueue.main.async(execute: block)
    }
}
