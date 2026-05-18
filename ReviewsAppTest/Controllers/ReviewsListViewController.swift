import UIKit

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
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.register(ReviewCell.self, forCellReuseIdentifier: ReviewCell.reuseID)
        tv.dataSource = self
        tv.delegate   = self
        return tv
    }()

    private lazy var stateView: StateView = {
        let sv = StateView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.onRetry  = { [weak self] in self?.viewModel.retry() }
        sv.isHidden = true
        return sv
    }()

    private lazy var sortSegmentControl: UISegmentedControl = {
        let items = SortOption.allCases.map { $0.rawValue }
        let sc    = UISegmentedControl(items: items)
        sc.selectedSegmentIndex = 0
        sc.translatesAutoresizingMaskIntoConstraints = false
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
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // Created once via lazy var — only errorFooterLabel.text is updated on each error
    // Avoids recreating the footer view on every pagination error
    private lazy var errorFooter: UIView = makeErrorFooterView()

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
        
        
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            sortSegmentControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            sortSegmentControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            sortSegmentControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            tableView.topAnchor.constraint(equalTo: sortSegmentControl.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // stateView occupies the same frame as tableView
            // No need to show/hide tableView — toggling stateView is sufficient
            stateView.topAnchor.constraint(equalTo: sortSegmentControl.bottomAnchor),
            stateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stateView.bottomAnchor.constraint(equalTo: view.bottomAnchor),


            // errorStack — centred inside the errorFooter container
            errorStack.centerXAnchor.constraint(equalTo: errorFooter.centerXAnchor),
            errorStack.centerYAnchor.constraint(equalTo: errorFooter.centerYAnchor),
            errorStack.leadingAnchor.constraint(equalTo: errorFooter.leadingAnchor, constant: 16),
            errorStack.trailingAnchor.constraint(equalTo: errorFooter.trailingAnchor, constant: -16),
        ])
    }

    // MARK: - Actions

    @objc private func sortChanged(_ sender: UISegmentedControl) {
        let selected = SortOption.allCases[sender.selectedSegmentIndex]
        viewModel.changeSort(to: selected)
    }

    // MARK: - State Rendering

    private func render(state: ViewState) {
    

        switch state {

        case .loading:
            stateView.isHidden = false
            

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
}

// For snapkit I can overcome within one week its not big deal ultimately code is in swift I have 5 years of experience with that thank you.
