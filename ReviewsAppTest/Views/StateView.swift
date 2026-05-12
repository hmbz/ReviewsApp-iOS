import UIKit

final class StateView: UIView {

    // MARK: - UI

    private let stackView: UIStackView = {
        let s = UIStackView()
        s.axis      = .vertical
        s.alignment = .center
        s.spacing   = 12
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private let iconLabel: UILabel = {
        let l = UILabel()
        l.font          = .systemFont(ofSize: 56)
        l.textAlignment = .center
        return l
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font          = .systemFont(ofSize: 20, weight: .semibold)
        l.textColor     = .label
        l.textAlignment = .center
        return l
    }()

    private let messageLabel: UILabel = {
        let l = UILabel()
        l.font          = .systemFont(ofSize: 15)
        l.textColor     = .secondaryLabel
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    let retryButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Try Again", for: .normal)
        b.titleLabel?.font   = .systemFont(ofSize: 16, weight: .semibold)
        b.backgroundColor    = .systemBlue
        b.setTitleColor(.white, for: .normal)
        b.layer.cornerRadius = 12
        b.contentEdgeInsets  = UIEdgeInsets(top: 13, left: 36, bottom: 13, right: 36)
        return b
    }()

    var onRetry: (() -> Void)?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = .systemBackground
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(stackView)
        [iconLabel, titleLabel, messageLabel, retryButton].forEach {
            stackView.addArrangedSubview($0)
        }

        stackView.setCustomSpacing(6,  after: iconLabel)
        stackView.setCustomSpacing(8,  after: titleLabel)
        stackView.setCustomSpacing(28, after: messageLabel)

        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -30),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40),
        ])

        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
    }

    @objc private func retryTapped() { onRetry?() }

    // MARK: - Configure

    func configure(icon: String, title: String, message: String, showRetry: Bool = false) {
        iconLabel.text        = icon
        titleLabel.text       = title
        messageLabel.text     = message
        retryButton.isHidden  = !showRetry
    }
}
