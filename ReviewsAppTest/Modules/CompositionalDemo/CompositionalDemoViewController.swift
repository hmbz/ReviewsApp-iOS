import UIKit

// ============================================================
// COMPOSITIONAL LAYOUT DEMO
// ============================================================
// Yeh screen 3 alag sections dikhati hai — sab ek CollectionView mein:
//
//  Section 0 → Horizontal Carousel   (orthogonalScrollingBehavior)
//  Section 1 → 2-Column Grid         (0.5 fractionalWidth per item)
//  Section 2 → Full Width List       (same as TableView rows)
//
// Koi UIScrollView nahi — CollectionView khud scroll karta hai.
// ============================================================

// MARK: - Section Model

enum DemoSection: Int, CaseIterable {
    case carousel = 0
    case grid     = 1
    case list     = 2

    var title: String {
        switch self {
        case .carousel: return "Featured"
        case .grid:     return "Categories"
        case .list:     return "Recent"
        }
    }
}

// MARK: - Demo Data

struct DemoItem {
    let title: String
    let subtitle: String
    let color: UIColor
}

// MARK: - ViewController

final class CompositionalDemoViewController: UIViewController {

    // MARK: - Data
    // 3 separate arrays — one per section

    private let carouselItems: [DemoItem] = [
        DemoItem(title: "Item 1", subtitle: "Horizontal scroll →", color: .systemBlue),
        DemoItem(title: "Item 2", subtitle: "Swipe to see more",   color: .systemPurple),
        DemoItem(title: "Item 3", subtitle: "80% screen width",    color: .systemTeal),
        DemoItem(title: "Item 4", subtitle: "groupPaging scroll",  color: .systemOrange),
    ]

    private let gridItems: [DemoItem] = [
        DemoItem(title: "Grid 1", subtitle: "0.5 width",   color: .systemRed),
        DemoItem(title: "Grid 2", subtitle: "0.5 width",   color: .systemGreen),
        DemoItem(title: "Grid 3", subtitle: "2 per row",   color: .systemYellow),
        DemoItem(title: "Grid 4", subtitle: "2 per row",   color: .systemIndigo),
        DemoItem(title: "Grid 5", subtitle: "auto wraps",  color: .systemPink),
        DemoItem(title: "Grid 6", subtitle: "auto wraps",  color: .systemMint),
    ]

    private let listItems: [DemoItem] = [
        DemoItem(title: "List Row 1", subtitle: "Full width — like TableView", color: .systemGray),
        DemoItem(title: "List Row 2", subtitle: "fractionalWidth(1.0)",        color: .systemGray),
        DemoItem(title: "List Row 3", subtitle: "estimated height",            color: .systemGray),
        DemoItem(title: "List Row 4", subtitle: "interGroupSpacing = 8",       color: .systemGray),
        DemoItem(title: "List Row 5", subtitle: "No UITableView needed",       color: .systemGray),
    ]

    // MARK: - CollectionView

    private lazy var collectionView: UICollectionView = {
        // Layout is built by our factory method below
        let cv = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        cv.backgroundColor = .systemBackground
        cv.register(DemoCarouselCell.self, forCellWithReuseIdentifier: DemoCarouselCell.reuseID)
        cv.register(DemoGridCell.self,     forCellWithReuseIdentifier: DemoGridCell.reuseID)
        cv.register(DemoListCell.self,     forCellWithReuseIdentifier: DemoListCell.reuseID)
        cv.register(
            DemoHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: DemoHeaderView.reuseID
        )
        cv.dataSource = self
        return cv
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Compositional Layout"
        view.backgroundColor = .systemBackground
        view.addSubview(collectionView)
        collectionView.frame = view.bounds
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
}

// MARK: - Layout Factory
// ============================================================
// This is the most important part.
// One layout, 3 different section behaviours.
// ============================================================

extension CompositionalDemoViewController {

    func makeLayout() -> UICollectionViewLayout {

        // The closure gives us sectionIndex so we return a different
        // NSCollectionLayoutSection for each section.
        return UICollectionViewCompositionalLayout { [weak self] sectionIndex, _ in
            guard let self else { return nil }
            let section = DemoSection(rawValue: sectionIndex) ?? .list

            switch section {
            case .carousel: return self.makeCarouselSection()
            case .grid:     return self.makeGridSection()
            case .list:     return self.makeListSection()
            }
        }
    }

    // ----------------------------------------------------------
    // SECTION 0 — Horizontal Carousel
    // Key: orthogonalScrollingBehavior = .groupPaging
    // ----------------------------------------------------------
    private func makeCarouselSection() -> NSCollectionLayoutSection {

        // Item fills the entire group
        let item = NSCollectionLayoutItem(
            layoutSize: .init(
                widthDimension: .fractionalWidth(1.0),   // 100% of group
                heightDimension: .fractionalHeight(1.0)  // 100% of group
            )
        )

        // Group is 80% of screen width — this creates the "peek" effect
        // You can see the next card slightly
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(
                widthDimension: .fractionalWidth(0.80),  // ← 80% = peek effect
                heightDimension: .absolute(180)
            ),
            subitems: [item]
        )

        let section = NSCollectionLayoutSection(group: group)

        // ← This ONE line makes it scroll horizontally!
        // .groupPaging   = snaps to each card
        // .continuous    = free scroll
        // .paging        = snaps by full screen width
        section.orthogonalScrollingBehavior = .groupPaging

        section.interGroupSpacing = 12
        section.contentInsets = .init(top: 8, leading: 16, bottom: 24, trailing: 16)
        section.boundarySupplementaryItems = [makeHeader()]
        return section
    }

    // ----------------------------------------------------------
    // SECTION 1 — 2-Column Grid
    // Key: fractionalWidth(0.5) = 2 items per row automatically
    // ----------------------------------------------------------
    private func makeGridSection() -> NSCollectionLayoutSection {

        // 0.5 = half the group width → 2 items fit in one row
        let item = NSCollectionLayoutItem(
            layoutSize: .init(
                widthDimension: .fractionalWidth(0.5),   // ← 50% = 2 columns
                heightDimension: .fractionalHeight(1.0)
            )
        )
        item.contentInsets = .init(top: 4, leading: 4, bottom: 4, trailing: 4)

        // Group height is fixed — items stretch to fill it
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(120)           // ← row height
            ),
            subitems: [item]
            // 2 items auto-fit because each is 0.5 wide
        )

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 0
        section.contentInsets = .init(top: 8, leading: 12, bottom: 24, trailing: 12)
        section.boundarySupplementaryItems = [makeHeader()]
        return section
    }

    // ----------------------------------------------------------
    // SECTION 2 — Full Width List (replaces UITableView)
    // Key: fractionalWidth(1.0) + estimated height
    // ----------------------------------------------------------
    private func makeListSection() -> NSCollectionLayoutSection {

        // Full width, height grows with content (like UITableView)
        let item = NSCollectionLayoutItem(
            layoutSize: .init(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(64)          // ← auto height
            )
        )

        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: .init(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(64)
            ),
            subitems: [item]
        )

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 8
        section.contentInsets = .init(top: 8, leading: 16, bottom: 24, trailing: 16)
        section.boundarySupplementaryItems = [makeHeader()]
        return section
    }

    // Section Header — shared across all sections
    private func makeHeader() -> NSCollectionLayoutBoundarySupplementaryItem {
        return NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: .init(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(44)
            ),
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
    }
}

// MARK: - DataSource

extension CompositionalDemoViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        DemoSection.allCases.count   // 3
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch DemoSection(rawValue: section) {
        case .carousel: return carouselItems.count
        case .grid:     return gridItems.count
        case .list:     return listItems.count
        case .none:     return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch DemoSection(rawValue: indexPath.section) {

        case .carousel:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: DemoCarouselCell.reuseID, for: indexPath
            ) as! DemoCarouselCell
            cell.configure(with: carouselItems[indexPath.item])
            return cell

        case .grid:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: DemoGridCell.reuseID, for: indexPath
            ) as! DemoGridCell
            cell.configure(with: gridItems[indexPath.item])
            return cell

        default:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: DemoListCell.reuseID, for: indexPath
            ) as! DemoListCell
            cell.configure(with: listItems[indexPath.item])
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: DemoHeaderView.reuseID,
            for: indexPath
        ) as! DemoHeaderView
        header.configure(with: DemoSection(rawValue: indexPath.section)?.title ?? "")
        return header
    }
}

// MARK: - Cells

// ----------------------------------------------------------
// Carousel Cell — colored card with title
// ----------------------------------------------------------
final class DemoCarouselCell: UICollectionViewCell {
    static let reuseID = "DemoCarouselCell"

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font      = .systemFont(ofSize: 22, weight: .bold)
        l.textColor = .white
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font      = .systemFont(ofSize: 14)
        l.textColor = UIColor.white.withAlphaComponent(0.8)
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 14
        contentView.clipsToBounds      = true

        [titleLabel, subtitleLabel].forEach { contentView.addSubview($0) }

        titleLabel.translatesAutoresizingMaskIntoConstraints    = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -12),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with item: DemoItem) {
        titleLabel.text          = item.title
        subtitleLabel.text       = item.subtitle
        contentView.backgroundColor = item.color
    }
}

// ----------------------------------------------------------
// Grid Cell — square card
// ----------------------------------------------------------
final class DemoGridCell: UICollectionViewCell {
    static let reuseID = "DemoGridCell"

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font          = .systemFont(ofSize: 15, weight: .semibold)
        l.textColor     = .white
        l.textAlignment = .center
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font          = .systemFont(ofSize: 11)
        l.textColor     = UIColor.white.withAlphaComponent(0.8)
        l.textAlignment = .center
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds      = true

        [titleLabel, subtitleLabel].forEach { contentView.addSubview($0) }

        titleLabel.translatesAutoresizingMaskIntoConstraints    = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -10),

            subtitleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with item: DemoItem) {
        titleLabel.text             = item.title
        subtitleLabel.text          = item.subtitle
        contentView.backgroundColor = item.color
    }
}

// ----------------------------------------------------------
// List Cell — full width row
// ----------------------------------------------------------
final class DemoListCell: UICollectionViewCell {
    static let reuseID = "DemoListCell"

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font      = .systemFont(ofSize: 16, weight: .semibold)
        l.textColor = .label
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font      = .systemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor    = .secondarySystemBackground
        contentView.layer.cornerRadius = 10
        contentView.clipsToBounds      = true

        [titleLabel, subtitleLabel].forEach { contentView.addSubview($0) }

        titleLabel.translatesAutoresizingMaskIntoConstraints    = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with item: DemoItem) {
        titleLabel.text    = item.title
        subtitleLabel.text = item.subtitle
    }
}

// ----------------------------------------------------------
// Section Header
// ----------------------------------------------------------
final class DemoHeaderView: UICollectionReusableView {
    static let reuseID = "DemoHeaderView"

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font      = .systemFont(ofSize: 20, weight: .bold)
        l.textColor = .label
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with title: String) {
        titleLabel.text = title
    }
}
