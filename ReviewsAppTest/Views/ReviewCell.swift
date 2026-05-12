import UIKit

final class ReviewCell: UITableViewCell {

    static let reuseID = "ReviewCell"

    // MARK: - UI Elements

    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor    = .secondarySystemBackground
        v.layer.cornerRadius = 14
        v.layer.shadowColor  = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.07
        v.layer.shadowOffset  = CGSize(width: 0, height: 2)
        v.layer.shadowRadius  = 6
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font      = .systemFont(ofSize: 16, weight: .semibold)
        l.textColor = .label
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let starsLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let dateLabel: UILabel = {
        let l = UILabel()
        l.font      = .systemFont(ofSize: 12)
        l.textColor = .tertiaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let reviewTextLabel: UILabel = {
        let l = UILabel()
        l.font          = .systemFont(ofSize: 14)
        l.textColor     = .secondaryLabel
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let reviewImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode        = .scaleAspectFill
        iv.clipsToBounds      = true
        iv.layer.cornerRadius = 10
        iv.backgroundColor    = .tertiarySystemFill
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private var imageHeightConstraint: NSLayoutConstraint!
    private var imageTopConstraint: NSLayoutConstraint!

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    override func prepareForReuse() {
        super.prepareForReuse()
        reviewImageView.image      = nil
        imageHeightConstraint.constant = 0
        imageTopConstraint.constant    = 0
    }

    // MARK: - Layout

    private func setupUI() {
        selectionStyle      = .none
        backgroundColor     = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(containerView)
        [nameLabel, starsLabel, dateLabel, reviewTextLabel, reviewImageView].forEach {
            containerView.addSubview($0)
        }

        imageHeightConstraint = reviewImageView.heightAnchor.constraint(equalToConstant: 0)
        imageTopConstraint    = reviewImageView.topAnchor.constraint(equalTo: reviewTextLabel.bottomAnchor, constant: 0)

        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            // Name
            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 14),
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 14),
            nameLabel.trailingAnchor.constraint(equalTo: starsLabel.leadingAnchor, constant: -8),

            // Stars
            starsLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            starsLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -14),
            starsLabel.widthAnchor.constraint(equalToConstant: 82),

            // Date
            dateLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            dateLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 14),
            dateLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -14),

            // Review text
            reviewTextLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 8),
            reviewTextLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 14),
            reviewTextLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -14),

            // Image
            imageTopConstraint,
            reviewImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 14),
            reviewImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -14),
            imageHeightConstraint,
            reviewImageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -14),
        ])
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

        // Image
        if let urlString = review.imageURL, let url = URL(string: urlString) {
            imageHeightConstraint.constant = 160
            imageTopConstraint.constant    = 10
            loadImage(from: url)
        } else {
            imageHeightConstraint.constant = 0
            imageTopConstraint.constant    = 0
        }
    }

    // MARK: - Image Loading

    private func loadImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self, let data, error == nil, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async { self.reviewImageView.image = image }
        }.resume()
    }
}
