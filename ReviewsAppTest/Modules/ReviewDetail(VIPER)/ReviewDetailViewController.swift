import UIKit
import SnapKit

final class ReviewDetailViewController: UIViewController {

    // MARK: - VIPER
    var presenter: ReviewDetailPresenterProtocol?

    // MARK: - Slider State
    private var timer: Timer?
    private var imageURLs: [String] = []

    // MARK: - UI — Scroll Container
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // MARK: - UI — Header Elements
    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 22, weight: .bold)
        l.textColor = .label
        return l
    }()

    private let starsLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 20)
        return l
    }()

    private let dateLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14)
        l.textColor = .tertiaryLabel
        return l
    }()

    // MARK: - UI — Image Slider
    private lazy var sliderCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.isPagingEnabled = true
        cv.showsHorizontalScrollIndicator = false
        cv.layer.cornerRadius = 12
        cv.clipsToBounds = true
        cv.backgroundColor = .tertiarySystemFill
        cv.register(ImageSliderCell.self, forCellWithReuseIdentifier: ImageSliderCell.reuseID)
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()

    private let pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.currentPageIndicatorTintColor = .white
        pc.pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.4)
        pc.hidesForSinglePage = true
        return pc
    }()

    private var sliderHeightConstraint: Constraint?

    // MARK: - UI — Review Text
    private let reviewTextLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16)
        l.textColor = .label
        l.numberOfLines = 0 //due to this it it will expand as long as text
        return l
    }()

    // MARK: - UI — Expandable Section
    private let expandHeaderButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = "  Review Details"
        config.image = UIImage(systemName: "chevron.down")
        config.imagePadding = 8
        config.imagePlacement = .trailing
        config.baseForegroundColor = .label
        
        let btn = UIButton(configuration: config)
        btn.contentHorizontalAlignment = .left
        btn.backgroundColor = .secondarySystemBackground
        btn.layer.cornerRadius = 10
        return btn
    }()

    private let expandStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.clipsToBounds = true
        return sv
    }()

    private let expandContentWrapper = UIView()
    private let expandContentLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14)
        l.textColor = .secondaryLabel
        l.numberOfLines = 0
        return l
    }()

    // MARK: - Lifecycle
    init() { super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupViews()
        setupConstraints()
        expandHeaderButton.addTarget(self, action: #selector(expandTapped), for: .touchUpInside)
        presenter?.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if imageURLs.count > 1 { startTimer() }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopTimer()
    }

    deinit {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Setup UI
    private func setupViews() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        [nameLabel, starsLabel, dateLabel, sliderCollectionView, pageControl,
         reviewTextLabel, expandHeaderButton, expandStack].forEach { contentView.addSubview($0) }
        
        expandStack.addArrangedSubview(expandContentWrapper)
        expandContentWrapper.addSubview(expandContentLabel)
    }

    private func setupConstraints() {
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView)
        }

        nameLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        starsLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(6)
            $0.leading.equalToSuperview().offset(16)
        }

        dateLabel.snp.makeConstraints {
            $0.centerY.equalTo(starsLabel)
            $0.trailing.equalToSuperview().offset(-16)
        }

        sliderCollectionView.snp.makeConstraints {
            $0.top.equalTo(starsLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            sliderHeightConstraint = $0.height.equalTo(200).constraint
        }

        pageControl.snp.makeConstraints {
            $0.bottom.equalTo(sliderCollectionView.snp.bottom).offset(-8)
            $0.centerX.equalTo(sliderCollectionView)
        }

        reviewTextLabel.snp.makeConstraints {
            $0.top.equalTo(sliderCollectionView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        expandHeaderButton.snp.makeConstraints {
            $0.top.equalTo(reviewTextLabel.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(48)
        }

        expandStack.snp.makeConstraints {
            $0.top.equalTo(expandHeaderButton.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().offset(-30)
        }

        expandContentLabel.snp.makeConstraints { $0.edges.equalToSuperview().inset(12) }
    }

    // MARK: - Timer Logic
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.scrollToNextImage()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

//    private func scrollToNextImage() {
//        let nextPage = (pageControl.currentPage + 1) % imageURLs.count
//        let offset = CGPoint(x: sliderCollectionView.bounds.width * CGFloat(nextPage), y: 0)
//        sliderCollectionView.setContentOffset(offset, animated: true)
//    }

    private func scrollToNextImage() {
        // 1. Safety Check: Array khali ho toh return kar jayen
        guard !imageURLs.isEmpty else { return }
        
        // 2. Logic: Circular scrolling (0 -> 1 -> 2 -> 0)
        let nextPage = (pageControl.currentPage + 1) % imageURLs.count
        
        // 3. Senior Move: scrollToItem use karein, yeh contentOffset se zyada reliable hai
        // kyunke yeh CollectionView ki layout calculation par depend karta hai.
        let indexPath = IndexPath(item: nextPage, section: 0)
        sliderCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        
        // 4. PageControl update
        pageControl.currentPage = nextPage
    }
    
    @objc private func expandTapped() { presenter?.didTapExpandCollapse() }
}

// MARK: - View Protocol
extension ReviewDetailViewController: ReviewDetailViewProtocol {
    func display(_ model: ReviewDisplayModel) {
        title = model.name
        nameLabel.text = model.name
        starsLabel.text = model.starsText
        starsLabel.textColor = model.starsColor
        dateLabel.text = model.dateText
        reviewTextLabel.text = model.reviewText
        expandContentLabel.text = model.expandedContent
        
        imageURLs = model.imageURLs
        pageControl.numberOfPages = imageURLs.count
        
        if imageURLs.isEmpty {
            sliderHeightConstraint?.update(offset: 0)
            sliderCollectionView.isHidden = true
            pageControl.isHidden = true
        } else {
            sliderHeightConstraint?.update(offset: 200)
            sliderCollectionView.isHidden = false
            pageControl.isHidden = model.imageURLs.count < 2
            sliderCollectionView.reloadData()
        }
    }

    func setExpanded(_ expanded: Bool) {
        UIView.animate(withDuration: 0.3) {
            self.expandContentWrapper.isHidden = !expanded
            let angle: CGFloat = expanded ? .pi : 0
            self.expandHeaderButton.imageView?.transform = CGAffineTransform(rotationAngle: angle)
        }
    }
}

// MARK: - CollectionView & ScrollDelegate
extension ReviewDetailViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { imageURLs.count }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageSliderCell.reuseID, for: indexPath) as! ImageSliderCell
        cell.configure(with: imageURLs[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        collectionView.bounds.size
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === sliderCollectionView else { return }
        let page = Int((scrollView.contentOffset.x / scrollView.bounds.width).rounded())
        if pageControl.currentPage != page { pageControl.currentPage = page }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) { stopTimer() }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) { if imageURLs.count > 1 { startTimer() } }
}
