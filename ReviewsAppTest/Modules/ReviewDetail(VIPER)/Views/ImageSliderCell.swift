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
    private let placeholderView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "photo")
        iv.tintColor = .systemGray3
        iv.contentMode = .scaleAspectFit
        iv.isHidden = true
        return iv
    }()

    private let loader = ImageLoader()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        contentView.addSubview(placeholderView)

        imageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        placeholderView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(60)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    func configure(with urlString: String) {
        guard let url = URL(string: urlString) else {
            showPlaceholder()   // invalid URL — show placeholder immediately
            return
        }
        loader.load(from: url) { [weak self] image in
            if let image {
                self?.imageView.image = image
                self?.placeholderView.isHidden = true
            } else {
                self?.showPlaceholder()  // network failure or bad data
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        loader.cancel()
        imageView.image = nil
        placeholderView.isHidden = true
    }

    // MARK: - Private

    private func showPlaceholder() {
        imageView.image = nil
        placeholderView.isHidden = false
    }
}
