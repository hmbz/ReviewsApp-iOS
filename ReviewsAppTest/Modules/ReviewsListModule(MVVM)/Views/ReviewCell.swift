import UIKit
import SnapKit

final class ReviewCell: UITableViewCell {

    static let reuseID = "ReviewCell"

    // MARK: - UI Elements

    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor     = .secondarySystemBackground
        v.layer.cornerRadius  = 14
        v.layer.shadowColor   = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.07
        v.layer.shadowOffset  = CGSize(width: 0, height: 2)
        v.layer.shadowRadius  = 6
        return v
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font      = .systemFont(ofSize: 16, weight: .semibold)
        l.textColor = .label
        return l
    }()

    private let starsLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15)
        return l
    }()

    private let dateLabel: UILabel = {
        let l = UILabel()
        l.font      = .systemFont(ofSize: 12)
        l.textColor = .tertiaryLabel
        return l
    }()

    private let reviewTextLabel: UILabel = {
        let l = UILabel()
        l.font          = .systemFont(ofSize: 14)
        l.textColor     = .secondaryLabel
        l.numberOfLines = 0
        return l
    }()

    private let reviewImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode        = .scaleAspectFill
        iv.clipsToBounds      = true
        iv.layer.cornerRadius = 10
        iv.backgroundColor    = .tertiarySystemFill
        return iv
    }()

    // SnapKit stored constraints for dynamic updates
    private var imageHeightConstraint: Constraint?
    private var imageTopConstraint: Constraint?

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    override func prepareForReuse() {
        super.prepareForReuse()
        reviewImageView.image = nil
        imageHeightConstraint?.update(offset: 0)
        imageTopConstraint?.update(offset: 0)
    }

    // MARK: - Layout

    private func setupUI() {
        selectionStyle              = .none
        backgroundColor             = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(containerView)
        [nameLabel, starsLabel, dateLabel, reviewTextLabel, reviewImageView].forEach {
            containerView.addSubview($0)
        }

        // Container
        containerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-8)
        }

        // Name label
        nameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.equalToSuperview().offset(14)
            make.trailing.equalTo(starsLabel.snp.leading).offset(-8)
        }

        // Stars label
        starsLabel.snp.makeConstraints { make in
            make.centerY.equalTo(nameLabel)
            make.trailing.equalToSuperview().offset(-14)
            make.width.equalTo(82)
        }

        // Date label
        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().offset(14)
            make.trailing.equalToSuperview().offset(-14)
        }

        // Review text
        reviewTextLabel.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(14)
            make.trailing.equalToSuperview().offset(-14)
        }

        // Image — store the two dynamic constraints
        reviewImageView.snp.makeConstraints { make in
            imageTopConstraint    = make.top.equalTo(reviewTextLabel.snp.bottom).offset(0).constraint
            make.leading.equalToSuperview().offset(14)
            make.trailing.equalToSuperview().offset(-14)
            imageHeightConstraint = make.height.equalTo(0).constraint
            make.bottom.equalToSuperview().offset(-14)
        }
    }

    // MARK: - Configure

    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df
    }()

    func configure(with review: Review) {
        nameLabel.text       = review.userName
        reviewTextLabel.text = review.text
        dateLabel.text       = Self.dateFormatter.string(from: review.createdAt)

        // Stars
        let filled = String(repeating: "★", count: review.rating)
        let empty  = String(repeating: "☆", count: 5 - review.rating)
        starsLabel.text = filled + empty
        switch review.rating {
        case 4...5: starsLabel.textColor = .systemYellow
        case 3:     starsLabel.textColor = .systemOrange
        default:    starsLabel.textColor = .systemRed
        }

        // Show thumbnail from first image URL, hide image view if none
        if let urlString = review.imageURLs.first, let url = URL(string: urlString) {
            imageHeightConstraint?.update(offset: 160)
            imageTopConstraint?.update(offset: 10)
            loadImage(from: url)
        } else {
            imageHeightConstraint?.update(offset: 0)
            imageTopConstraint?.update(offset: 0)
        }
    }

    // MARK: - Image Loading

    private func loadImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self, let data, error == nil, let image = UIImage(data: data) else { return }
            DispatchQueue.onMain { self.reviewImageView.image = image }
        }.resume()
    }
}
