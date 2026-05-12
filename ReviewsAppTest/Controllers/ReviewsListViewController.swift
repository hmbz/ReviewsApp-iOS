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
        sv.onRetry = { [weak self] in self?.viewModel.retry() }
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

    private let footerSpinner: UIActivityIndicatorView = {
        let a = UIActivityIndicatorView(style: .medium)
        a.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 60)
        return a
    }()

    private let footerEndLabel: UILabel = {
        let l = UILabel()
        l.text          = "✓  No more reviews"
        l.font          = .systemFont(ofSize: 13)
        l.textColor     = .tertiaryLabel
        l.textAlignment = .center
        l.frame         = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 52)
        return l
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
        setupLayout()
        viewModel.delegate = self
        viewModel.loadFirstPage()
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        title = "Reviews"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
    }

    private func setupLayout() {
        view.backgroundColor = .systemBackground

        // Sort control pinned below nav bar
        view.addSubview(sortSegmentControl)
        view.addSubview(tableView)
        view.addSubview(stateView)

        NSLayoutConstraint.activate([
            sortSegmentControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            sortSegmentControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            sortSegmentControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            tableView.topAnchor.constraint(equalTo: sortSegmentControl.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stateView.topAnchor.constraint(equalTo: sortSegmentControl.bottomAnchor),
            stateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stateView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        stateView.isHidden = true
    }

    // MARK: - Actions

    @objc private func sortChanged(_ sender: UISegmentedControl) {
        let selected = SortOption.allCases[sender.selectedSegmentIndex]
        viewModel.changeSort(to: selected)
    }

    // MARK: - State Rendering

    private func render(state: ViewState) {
        // Remove all spinners
        removeSubSpinners()

        switch state {

        case .loading:
            tableView.isHidden  = true
            stateView.isHidden  = false
            showFullScreenSpinner()

        case .loaded:
            stateView.isHidden      = false
            tableView.isHidden      = false
            stateView.isHidden      = true
            tableView.tableFooterView = nil
            tableView.reloadData()

        case .error(let message):
            if viewModel.reviews.isEmpty {
                // Full-screen error
                tableView.isHidden = true
                stateView.isHidden = false
                stateView.configure(icon: "⚠️", title: "Something Went Wrong", message: message, showRetry: true)
            } else {
                // Inline footer error
                tableView.isHidden    = false
                stateView.isHidden    = true
                tableView.tableFooterView = makeErrorFooter(message: message)
                tableView.reloadData()
            }

        case .empty:
            tableView.isHidden = true
            stateView.isHidden = false
            stateView.configure(icon: "📭", title: "No Reviews Yet", message: "Be the first to leave a review for this product!")

        case .noMoreItems:
            tableView.isHidden            = false
            stateView.isHidden            = true
            tableView.tableFooterView     = footerEndLabel
            tableView.reloadData()
        }
    }

    // MARK: - Helpers

    private func showFullScreenSpinner() {
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.tag = 999
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        stateView.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: stateView.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: stateView.centerYAnchor),
        ])
    }

    private func removeSubSpinners() {
        stateView.subviews.filter { $0.tag == 999 }.forEach { $0.removeFromSuperview() }
    }

    private func makeErrorFooter(message: String) -> UIView {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 90))

        let label = UILabel()
        label.text          = "⚠️  \(message)"
        label.font          = .systemFont(ofSize: 13)
        label.textColor     = .systemRed
        label.textAlignment = .center
        label.numberOfLines = 0

        let btn = UIButton(type: .system)
        btn.setTitle("Retry", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        btn.addTarget(self, action: #selector(retryFromFooter), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [label, btn])
        stack.axis      = .vertical
        stack.spacing   = 6
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
        ])
        return container
    }

    @objc private func retryFromFooter() {
        viewModel.retry()
    }
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
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ReviewCell.reuseID, for: indexPath
        ) as? ReviewCell else {
            return UITableViewCell()
        }
        cell.configure(with: viewModel.reviews[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate (Pagination trigger)

extension ReviewsListViewController: UITableViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY       = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight   = scrollView.frame.height

        guard contentHeight > 0 else { return }

        if offsetY > contentHeight - frameHeight - 120 {
            if case .loaded = viewModel.state {
                tableView.tableFooterView = footerSpinner
                footerSpinner.startAnimating()
                viewModel.loadNextPageIfNeeded()
            }
        }
    }
}
