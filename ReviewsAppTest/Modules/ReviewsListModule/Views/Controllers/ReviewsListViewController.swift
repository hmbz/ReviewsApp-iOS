import UIKit
import SnapKit

final class ReviewsListViewController: UIViewController {

    // MARK: - Dependencies
    private let viewModel: ReviewsViewModel

    // MARK: - UI

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor    = .systemBackground
        tv.separatorStyle     = .none
        tv.rowHeight          = UITableView.automaticDimension
        tv.estimatedRowHeight = 160
        tv.register(ReviewCell.self, forCellReuseIdentifier: ReviewCell.reuseID)
        tv.dataSource = self
        tv.delegate   = self
        return tv
    }()

    private lazy var stateView: StateView = {
        let sv = StateView()
        sv.onRetry  = { [weak self] in self?.viewModel.retry() }
        sv.isHidden = true
        return sv
    }()

    private lazy var sortSegmentControl: UISegmentedControl = {
        let items = SortOption.allCases.map { $0.rawValue }
        let sc    = UISegmentedControl(items: items)
        sc.selectedSegmentIndex = 0
        sc.addTarget(self, action: #selector(sortChanged(_:)), for: .valueChanged)
        return sc
    }()

    // Using width: 0 instead of UIScreen.main.bounds.width (deprecated in iOS 16+)
    // The tableView automatically stretches footer views to its own width
    private lazy var footerSpinner: UIActivityIndicatorView = {
        let a = UIActivityIndicatorView(style: .medium)
        a.frame = CGRect(x: 0, y: 0, width: 0, height: 60)
        return a
    }()

    private lazy var footerEndLabel: UILabel = {
        let l = UILabel()
        l.text          = "✓  No more reviews"
        l.font          = .systemFont(ofSize: 13)
        l.textColor     = .tertiaryLabel
        l.textAlignment = .center
        l.frame         = CGRect(x: 0, y: 0, width: 0, height: 52)
        return l
    }()

    // errorFooterLabel text is updated on each pagination error — view is reused, not recreated
    private lazy var errorFooterLabel: UILabel = {
        let l = UILabel()
        l.font          = .systemFont(ofSize: 13)
        l.textColor     = .systemRed
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    // Stored property so its constraints can be centralised in setupConstraints()
    // makeErrorFooterView() only builds the container and adds errorStack — no constraints inside
    private lazy var errorStack: UIStackView = {
        let btn = UIButton(type: .system)
        btn.setTitle("Retry", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        btn.addTarget(self, action: #selector(retryFromFooter), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [errorFooterLabel, btn])
        stack.axis      = .vertical
        stack.spacing   = 6
        stack.alignment = .center
        return stack
    }()

    // Created once via lazy var — only errorFooterLabel.text is updated on each error
    // Avoids recreating the footer view on every pagination error
    private lazy var errorFooter: UIView = makeErrorFooterView()

    // Stored property so its constraints live in setupConstraints()
    // showFullScreenSpinner() only toggles visibility — no layout code inside
    private lazy var fullScreenSpinner: UIActivityIndicatorView = {
        let s = UIActivityIndicatorView(style: .large)
        s.isHidden = true
        return s
    }()

    // MARK: - Init

    init(viewModel: ReviewsViewModel = ReviewsViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupViews()
        setupConstraints()
        viewModel.delegate = self
        viewModel.loadFirstPage()
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        title = "Reviews"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
    }

    // Separated into two functions: one for adding subviews, one for constraints
    // This improves readability and makes each function single-responsibility
    private func setupViews() {
        view.backgroundColor = .systemBackground
        view.addSubview(sortSegmentControl)
        view.addSubview(tableView)
        // stateView is added on top of tableView with the same constraints
        // Only stateView.isHidden is toggled — tableView stays in place always
        view.addSubview(stateView)
        // fullScreenSpinner lives inside stateView — hidden until loading state
        stateView.addSubview(fullScreenSpinner)
    }

    private func setupConstraints() {
        sortSegmentControl.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(sortSegmentControl.snp.bottom).offset(10)
            make.leading.trailing.bottom.equalToSuperview()
        }

        // stateView occupies the same frame as tableView
        // No need to show/hide tableView — toggling stateView is sufficient
        stateView.snp.makeConstraints { make in
            make.top.equalTo(sortSegmentControl.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        // fullScreenSpinner — centred inside stateView
        fullScreenSpinner.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        // errorStack — centred inside the errorFooter container
        errorStack.snp.makeConstraints { make in
            make.centerX.centerY.equalTo(errorFooter)
            make.leading.equalTo(errorFooter).offset(16)
            make.trailing.equalTo(errorFooter).offset(-16)
        }
    }

    // MARK: - Actions

    @objc private func sortChanged(_ sender: UISegmentedControl) {
        let selected = SortOption.allCases[sender.selectedSegmentIndex]
        viewModel.changeSort(to: selected)
    }

    // MARK: - State Rendering

    private func render(state: ViewState) {
        hideFullScreenSpinner()

        switch state {

        case .loading:
            stateView.isHidden = false
            showFullScreenSpinner()

        case .loaded:
            stateView.isHidden        = true
            tableView.tableFooterView = nil
            insertNewRows()

        case .error(let message):
            if viewModel.reviews.isEmpty {
                stateView.isHidden = false
                stateView.configure(icon: "⚠️", title: "Something Went Wrong", message: message, showRetry: true)
            } else {
                stateView.isHidden        = true
                errorFooterLabel.text     = "⚠️  \(message)"
                // No reloadData() — only the footer view is changing, not the data
                tableView.tableFooterView = errorFooter
            }

        case .empty:
            stateView.isHidden = false
            stateView.configure(icon: "📭", title: "No Reviews Yet", message: "Be the first to leave a review!")

        case .noMoreItems:
            stateView.isHidden        = true
            tableView.tableFooterView = footerEndLabel
            insertNewRows()
        }
    }

    // MARK: - Helpers

    // Uses insertRows instead of reloadData for pagination
    // Preserves scroll position and provides smooth insert animation
    // reloadData() is only called for the first page or after a sort reset
    private func insertNewRows() {
        let previousCount = tableView.numberOfRows(inSection: 0)
        let newCount      = viewModel.reviews.count

        if previousCount == 0 {
            tableView.reloadData()
        } else {
            let newIndexPaths = (previousCount..<newCount).map {
                IndexPath(row: $0, section: 0)
            }
            tableView.insertRows(at: newIndexPaths, with: .automatic)
        }
    }

    // Shows the pre-built spinner — no layout work here, constraints live in setupConstraints()
    private func showFullScreenSpinner() {
        fullScreenSpinner.isHidden = false
        fullScreenSpinner.startAnimating()
    }

    // Hides the spinner without removing it — stays in hierarchy for reuse
    private func hideFullScreenSpinner() {
        fullScreenSpinner.stopAnimating()
        fullScreenSpinner.isHidden = true
    }

    // Called once by the lazy var — adds errorStack to the container, no constraints here
    // All constraints for errorStack are centralised in setupConstraints()
    private func makeErrorFooterView() -> UIView {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 90))
        container.addSubview(errorStack)
        return container
    }

    @objc private func retryFromFooter() { viewModel.retry() }
}

// MARK: - ReviewsViewModelDelegate

extension ReviewsListViewController: ReviewsViewModelDelegate {
    func viewModelDidUpdateState(_ viewModel: ReviewsViewModel) {
        render(state: viewModel.state)
    }
}

// MARK: - UITableViewDataSource

extension ReviewsListViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.reviews.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Using optional cast (as?) — if the cast fails, configure is simply skipped
        // and an empty cell is returned safely without crashing
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ReviewCell.reuseID, for: indexPath
        )
        (cell as? ReviewCell)?.configure(with: viewModel.reviews[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ReviewsListViewController: UITableViewDelegate {

    // willDisplay is preferred over scrollViewDidScroll for pagination
    // No manual offset calculations needed — triggers exactly when the last cell appears
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let lastIndex = viewModel.reviews.count - 1
        guard indexPath.row == lastIndex, case .loaded = viewModel.state else { return }
        tableView.tableFooterView = footerSpinner
        footerSpinner.startAnimating()
        viewModel.loadNextPageIfNeeded()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let review   = viewModel.reviewSelected(at: indexPath.row)
        // Detail screen uses VIPER — Router assembles and returns the module
        let detailVC = ReviewDetailRouter.createModule(with: review)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
