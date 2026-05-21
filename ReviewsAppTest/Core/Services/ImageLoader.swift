import UIKit

// MARK: - ImageLoader
// Handles async image fetching with:
// - NSCache to avoid re-downloading the same image
// - Cancellable URLSessionDataTask to prevent flickering on fast scrolls

final class ImageLoader {

    // Shared cache across all ImageLoader instances
    private static let cache = NSCache<NSString, UIImage>()

    private var currentTask: URLSessionDataTask?

    /// Load image from URL — returns cached result immediately if available.
    /// Cancels any previously running task before starting a new one.
    /// - Parameters:
    ///   - completion: Called with the loaded image on success.
    ///   - onError: Called when network fails or data cannot be decoded as an image.
    func load(from url: URL,
              completion: @escaping (UIImage) -> Void,
              onError: @escaping () -> Void) {
        let key = url.absoluteString as NSString

        // Return from cache instantly — no network call needed
        if let cached = Self.cache.object(forKey: key) {
            completion(cached)
            return
        }

        // Cancel previous task before starting a new one
        currentTask?.cancel()

        currentTask = URLSession.shared.dataTask(with: url) { data, _, error in
            // Ignore cancellation errors — they are expected
            if let urlError = error as? URLError, urlError.code == .cancelled { return }

            guard let data, let image = UIImage(data: data) else {
                DispatchQueue.main.async { onError() }
                return
            }

            Self.cache.setObject(image, forKey: key)
            DispatchQueue.main.async { completion(image) }
        }
        currentTask?.resume()
    }

    /// Cancel the running task — call from prepareForReuse to prevent flickering.
    func cancel() {
        currentTask?.cancel()
        currentTask = nil
    }
}
