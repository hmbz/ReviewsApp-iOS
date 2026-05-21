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

    private let loader = ImageLoader()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    func configure(with urlString: String) {
        guard let url = URL(string: urlString) else { return }
        loader.load(from: url) { [weak self] image in
            self?.imageView.image = image
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        loader.cancel()
        imageView.image = nil
    }
}
