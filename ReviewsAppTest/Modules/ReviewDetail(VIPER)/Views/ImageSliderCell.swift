import UIKit
import SnapKit

// MARK: - ImageSliderCell
// Used by the image slider UICollectionView in ReviewDetailViewController.
// Each cell owns its ImageLoader — cancelled in prepareForReuse to prevent
// image flickering when the slider is swiped quickly.

final class ImageSliderCell: UICollectionViewCell {
    static let reuseID = "ImageSliderCell"

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .tertiarySystemFill
        return iv
    }()

    // Shown when URL is invalid or network request fails
    private lazy var errorView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "exclamationmark.triangle")
        iv.tintColor = .systemOrange
        iv.contentMode = .scaleAspectFit
        iv.isHidden = true
        return iv
    }()

    private let loader = ImageLoader()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        contentView.addSubview(errorView)

        imageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        errorView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(44)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    func configure(with urlString: String) {
        guard let url = URL(string: urlString) else {
            showError()   // invalid URL — no point making a network request
            return
        }
        loader.load(from: url) { [weak self] image in
            self?.imageView.image = image
            self?.errorView.isHidden = true
        } onError: { [weak self] in
            self?.showError()  // network failure or bad image data
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        loader.cancel()
        imageView.image = nil
        errorView.isHidden = true
    }

    // MARK: - Private

    private func showError() {
        imageView.image = nil
        errorView.isHidden = false
    }
}
