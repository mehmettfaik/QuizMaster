import UIKit
import DGCharts
import Combine
import Charts
import FirebaseAuth

class StatsViewController: UIViewController, ChartViewDelegate, UITableViewDelegate, UITableViewDataSource {
    private let viewModel = UserViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    private let segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: [
            LanguageManager.shared.localizedString(for: "statistics"),
            LanguageManager.shared.localizedString(for: "leaderboard")
        ])
        control.selectedSegmentIndex = 0
        control.translatesAutoresizingMaskIntoConstraints = false
        
        // Appearance customization
        let purpleColor = UIColor.primaryPurple
        control.backgroundColor = .systemGray5
        control.selectedSegmentTintColor = purpleColor
        
        // Text attributes for normal state
        let normalTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.darkGray
        ]
        control.setTitleTextAttributes(normalTextAttributes, for: .normal)
        
        // Text attributes for selected state
        let selectedTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white
        ]
        control.setTitleTextAttributes(selectedTextAttributes, for: .selected)
        
        return control
    }()
    
    private let leaderboardView: UIView = {
        let view = UIView()
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let leaderboardTableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        return tableView
    }()
    
    private let timeFilterControl: UISegmentedControl = {
        let control = UISegmentedControl(items: [
            LanguageManager.shared.localizedString(for: "this_week"),
            LanguageManager.shared.localizedString(for: "this_month"),
            LanguageManager.shared.localizedString(for: "all_time")
        ])
        control.selectedSegmentIndex = 0
        control.translatesAutoresizingMaskIntoConstraints = false
        
        // Appearance customization
        let purpleColor = UIColor.primaryPurple
        control.backgroundColor = .systemGray5
        control.selectedSegmentTintColor = purpleColor
        
        // Text attributes for normal state
        let normalTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.darkGray
        ]
        control.setTitleTextAttributes(normalTextAttributes, for: .normal)
        
        // Text attributes for selected state
        let selectedTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white
        ]
        control.setTitleTextAttributes(selectedTextAttributes, for: .selected)
        
        return control
    }()
    
    private var leaderboardUsers: [User] = []
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .primaryPurple
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let pointsLabel: UILabel = {
        let label = UILabel()
        label.text = LanguageManager.shared.localizedString(for: "points").uppercased()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let pointsValueLabel: UILabel = {
            let label = UILabel()
            label.text = "0"
            label.font = .systemFont(ofSize: 32, weight: .bold)
            label.textColor = .white
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()
    
    private let quizzesLabel: UILabel = {
        let label = UILabel()
        label.text = LanguageManager.shared.localizedString(for: "quizzes").uppercased()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let quizzesValueLabel: UILabel = {
            let label = UILabel()
            label.text = "0"
            label.font = .systemFont(ofSize: 28, weight: .bold)
            label.textColor = .white
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()
    
    private let rankLabel: UILabel = {
        let label = UILabel()
        label.text = LanguageManager.shared.localizedString(for: "world_rank").uppercased()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let rankValueLabel: UILabel = {
            let label = UILabel()
            label.text = "#0"
            label.font = .systemFont(ofSize: 32, weight: .bold)
            label.textColor = .white
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private let statsView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 20
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let noDataView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let noDataImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "chart.bar.xaxis")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .primaryPurple
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let noDataLabel: UILabel = {
        let label = UILabel()
        label.text = LanguageManager.shared.localizedString(for: "stats_warning")
        label.textColor = .darkGray
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let pieChartView: PieChartView = {
        let chartView = PieChartView()
        chartView.translatesAutoresizingMaskIntoConstraints = false
        return chartView
    }()
    
    private let lineChartView: BarChartView = {
        let chartView = BarChartView()
        chartView.isHidden = true
        chartView.translatesAutoresizingMaskIntoConstraints = false
        return chartView
    }()
    
    private let categoryLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .primaryPurple
        label.textAlignment = .center
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let topThreeContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let topThreeStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        setupPieChart()
        setupLineChart()
        
        // Set initial view state
        statsView.isHidden = false
        leaderboardView.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadUserProfile()
        
        // Load leaderboard if we're on the leaderboard tab
        if segmentedControl.selectedSegmentIndex == 1 {
            loadLeaderboard()
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        // Add header view directly to main view (outside scroll area)
        view.addSubview(headerView)
        headerView.addSubview(pointsLabel)
        headerView.addSubview(pointsValueLabel)
        headerView.addSubview(quizzesLabel)
        headerView.addSubview(quizzesValueLabel)
        headerView.addSubview(rankLabel)
        headerView.addSubview(rankValueLabel)
        
        // Add segmented control below header
        view.addSubview(segmentedControl)
        
        // Add scroll view and content view
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Add loading indicator to the main view so it's always visible
        view.addSubview(loadingIndicator)
        
        // Add stats view and no data view to the content view
        contentView.addSubview(statsView)
        contentView.addSubview(noDataView)
        noDataView.addSubview(noDataImageView)
        noDataView.addSubview(noDataLabel)
        
        statsView.addSubview(pieChartView)
        statsView.addSubview(categoryLabel)
        statsView.addSubview(lineChartView)
        
        // Add leaderboard view
        view.addSubview(leaderboardView)
        leaderboardView.addSubview(timeFilterControl)
        
        // Add top three container and stack view
        leaderboardView.addSubview(topThreeContainerView)
        topThreeContainerView.addSubview(topThreeStackView)
        
        // Create and add top 3 cards
        let secondPlaceCard = createTopUserCard(rank: 2)
        let firstPlaceCard = createTopUserCard(rank: 1)
        let thirdPlaceCard = createTopUserCard(rank: 3)
        
        // İlk 3'ü farklı boyutlarda göstermek için
        NSLayoutConstraint.activate([
            firstPlaceCard.heightAnchor.constraint(equalToConstant: 230),
            firstPlaceCard.widthAnchor.constraint(equalToConstant: 140),
            secondPlaceCard.heightAnchor.constraint(equalToConstant: 190),
            secondPlaceCard.widthAnchor.constraint(equalToConstant: 120),
            thirdPlaceCard.heightAnchor.constraint(equalToConstant: 190),
            thirdPlaceCard.widthAnchor.constraint(equalToConstant: 120)
        ])
        
        topThreeStackView.addArrangedSubview(secondPlaceCard)
        topThreeStackView.addArrangedSubview(firstPlaceCard)
        topThreeStackView.addArrangedSubview(thirdPlaceCard)
        
        leaderboardView.addSubview(leaderboardTableView)
        
        // Setup leaderboard table view
        leaderboardTableView.delegate = self
        leaderboardTableView.dataSource = self
        leaderboardTableView.register(LeaderboardCell.self, forCellReuseIdentifier: LeaderboardCell.identifier)
        
        // Add target to segmented control
        segmentedControl.addTarget(self, action: #selector(segmentedControlValueChanged), for: .valueChanged)
        timeFilterControl.addTarget(self, action: #selector(timeFilterValueChanged), for: .valueChanged)
        
        NSLayoutConstraint.activate([
            // Header view constraints
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 120),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            // Points section constraints
            pointsLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            pointsLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            pointsValueLabel.leadingAnchor.constraint(equalTo: pointsLabel.leadingAnchor),
            pointsValueLabel.topAnchor.constraint(equalTo: pointsLabel.bottomAnchor, constant: 4),
            
            // Quizzes section constraints
            quizzesLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            quizzesLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor, constant: 10),
            
            quizzesValueLabel.centerXAnchor.constraint(equalTo: quizzesLabel.centerXAnchor),
            quizzesValueLabel.topAnchor.constraint(equalTo: quizzesLabel.bottomAnchor, constant: 4),
            
            // Rank section constraints
            rankLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            rankLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            rankValueLabel.trailingAnchor.constraint(equalTo: rankLabel.trailingAnchor),
            rankValueLabel.topAnchor.constraint(equalTo: rankLabel.bottomAnchor, constant: 4),
            
            // Segmented control constraints - moved closer to header
            segmentedControl.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 8),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Scroll view constraints
            scrollView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view constraints
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Stats view constraints
            statsView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            statsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            statsView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            statsView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            // Leaderboard view constraints
            leaderboardView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
            leaderboardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            leaderboardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            leaderboardView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Time filter control constraints
            timeFilterControl.topAnchor.constraint(equalTo: leaderboardView.topAnchor, constant: 16),
            timeFilterControl.leadingAnchor.constraint(equalTo: leaderboardView.leadingAnchor, constant: 16),
            timeFilterControl.trailingAnchor.constraint(equalTo: leaderboardView.trailingAnchor, constant: -16),
            
            // Top three container constraints
            topThreeContainerView.topAnchor.constraint(equalTo: timeFilterControl.bottomAnchor, constant: 16),
            topThreeContainerView.leadingAnchor.constraint(equalTo: leaderboardView.leadingAnchor),
            topThreeContainerView.trailingAnchor.constraint(equalTo: leaderboardView.trailingAnchor),
            topThreeContainerView.heightAnchor.constraint(equalToConstant: 220),
            
            // Top three stack view constraints
            topThreeStackView.centerXAnchor.constraint(equalTo: topThreeContainerView.centerXAnchor),
            topThreeStackView.centerYAnchor.constraint(equalTo: topThreeContainerView.centerYAnchor),
            
            // Update leaderboard table view constraints
            leaderboardTableView.topAnchor.constraint(equalTo: topThreeContainerView.bottomAnchor, constant: 16),
            leaderboardTableView.leadingAnchor.constraint(equalTo: leaderboardView.leadingAnchor),
            leaderboardTableView.trailingAnchor.constraint(equalTo: leaderboardView.trailingAnchor),
            leaderboardTableView.bottomAnchor.constraint(equalTo: leaderboardView.bottomAnchor),
            
            pieChartView.topAnchor.constraint(equalTo: statsView.topAnchor, constant: 10),
            pieChartView.leadingAnchor.constraint(equalTo: statsView.leadingAnchor, constant: 20),
            pieChartView.trailingAnchor.constraint(equalTo: statsView.trailingAnchor, constant: -20),
            pieChartView.heightAnchor.constraint(equalTo: pieChartView.widthAnchor, multiplier: 1.2),
            
            categoryLabel.topAnchor.constraint(equalTo: pieChartView.bottomAnchor, constant: 20),
            categoryLabel.leadingAnchor.constraint(equalTo: statsView.leadingAnchor, constant: 20),
            categoryLabel.trailingAnchor.constraint(equalTo: statsView.trailingAnchor, constant: -20),
            
            lineChartView.topAnchor.constraint(equalTo: categoryLabel.bottomAnchor, constant: 10),
            lineChartView.leadingAnchor.constraint(equalTo: statsView.leadingAnchor, constant: 20),
            lineChartView.trailingAnchor.constraint(equalTo: statsView.trailingAnchor, constant: -20),
            lineChartView.heightAnchor.constraint(equalToConstant: 200),
            lineChartView.bottomAnchor.constraint(lessThanOrEqualTo: statsView.bottomAnchor, constant: -20),
            
            // No Data View constraints
            noDataView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: -200),
            noDataView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            noDataView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            noDataView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            noDataImageView.centerXAnchor.constraint(equalTo: noDataView.centerXAnchor),
            noDataImageView.centerYAnchor.constraint(equalTo: noDataView.centerYAnchor, constant: -40),
            noDataImageView.widthAnchor.constraint(equalToConstant: 80),
            noDataImageView.heightAnchor.constraint(equalToConstant: 80),
            
            noDataLabel.topAnchor.constraint(equalTo: noDataImageView.bottomAnchor, constant: 20),
            noDataLabel.leadingAnchor.constraint(equalTo: noDataView.leadingAnchor, constant: 20),
            noDataLabel.trailingAnchor.constraint(equalTo: noDataView.trailingAnchor, constant: -20),
            noDataLabel.centerXAnchor.constraint(equalTo: noDataView.centerXAnchor),
        ])
        
        // Set a height constraint for the content view based on the statsView
        let contentHeightConstraint = contentView.heightAnchor.constraint(greaterThanOrEqualTo: view.heightAnchor)
        contentHeightConstraint.priority = .defaultLow
        contentHeightConstraint.isActive = true
    }
    
    @objc private func segmentedControlValueChanged() {
        let isLeaderboardSelected = segmentedControl.selectedSegmentIndex == 1
        statsView.isHidden = isLeaderboardSelected
        leaderboardView.isHidden = !isLeaderboardSelected
        noDataView.isHidden = isLeaderboardSelected
        
        if isLeaderboardSelected {
            loadLeaderboard()
        }
    }
    
    @objc private func timeFilterValueChanged() {
        loadLeaderboard()
    }
    
    private func showLeaderboardError(_ error: Error) {
        let alert = UIAlertController(
            title: LanguageManager.shared.localizedString(for: "error"),
            message: String(format: LanguageManager.shared.localizedString(for: "leaderboard_error"), error.localizedDescription),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: LanguageManager.shared.localizedString(for: "ok"), style: .default))
        present(alert, animated: true)
    }

    private func loadLeaderboard() {
        loadingIndicator.startAnimating()
        
        FirebaseService.shared.getLeaderboard { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.loadingIndicator.stopAnimating()
                
                switch result {
                case .success(let users):
                    self.leaderboardUsers = users
                    self.updateTopThreeCards()
                    self.leaderboardTableView.reloadData()
                case .failure(let error):
                    self.showLeaderboardError(error)
                }
            }
        }
    }
    
    // MARK: - UITableViewDelegate & UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(0, leaderboardUsers.count - 3) // İlk 3'ü çıkarıyoruz
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: LeaderboardCell.identifier, for: indexPath) as! LeaderboardCell
        let user = leaderboardUsers[indexPath.row + 3] // İlk 3'ü atladığımız için +3 ekliyoruz
        cell.configure(with: user, rank: indexPath.row + 4) // Sıralama numarasını 4'ten başlatıyoruz
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 88 // Cell height + padding
    }
    
    private func setupPieChart() {
        pieChartView.delegate = self
        pieChartView.chartDescription.enabled = false
        pieChartView.drawHoleEnabled = true
        pieChartView.holeColor = .clear
        pieChartView.holeRadiusPercent = 0.5
        pieChartView.rotationEnabled = true
        pieChartView.highlightPerTapEnabled = true
        pieChartView.animate(xAxisDuration: 1.0, yAxisDuration: 1.0)
        
        let legend = pieChartView.legend
        legend.horizontalAlignment = .center
        legend.verticalAlignment = .bottom
        legend.orientation = .horizontal
        legend.drawInside = false
        legend.xEntrySpace = 7
        legend.yEntrySpace = 0
        legend.yOffset = 0
        legend.font = UIFont.systemFont(ofSize: 15)
        
        let xAxis = lineChartView.xAxis
        xAxis.valueFormatter = IndexAxisValueFormatter(values: [
            LanguageManager.shared.localizedString(for: "correct"),
            LanguageManager.shared.localizedString(for: "wrong"),
            LanguageManager.shared.localizedString(for: "points")
        ])
    }
    
    private func setupLineChart() {
        lineChartView.rightAxis.enabled = false
        lineChartView.animate(xAxisDuration: 1.0, yAxisDuration: 1.0)
        lineChartView.legend.enabled = false
        
        let leftAxis = lineChartView.leftAxis
        leftAxis.labelTextColor = .black
        leftAxis.axisMinimum = 0
        leftAxis.drawGridLinesEnabled = false
        
        let xAxis = lineChartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelTextColor = .black
        xAxis.drawGridLinesEnabled = false
        xAxis.valueFormatter = IndexAxisValueFormatter(values: [
            LanguageManager.shared.localizedString(for: "correct"),
            LanguageManager.shared.localizedString(for: "wrong"),
            LanguageManager.shared.localizedString(for: "points")
        ])
        xAxis.granularity = 1
    }
    
    private func updatePieChart(with categoryStats: [String: CategoryStats]) {
        var entries: [PieChartDataEntry] = []
        
        for (category, stats) in categoryStats {
            let total = Double(stats.correctAnswers + stats.wrongAnswers)
            if total > 0 {
                let successRate = Double(stats.correctAnswers) / total * 100
                entries.append(PieChartDataEntry(value: successRate, label: category))
            }
        }
        
        let dataSet = PieChartDataSet(entries: entries, label: LanguageManager.shared.localizedString(for: "success_rates"))
        
        // Özel renkler tanımla
        dataSet.colors = [
            UIColor(red: 0.91, green: 0.31, blue: 0.35, alpha: 1.0),  // Kırmızı
            UIColor(red: 0.36, green: 0.72, blue: 0.36, alpha: 1.0),  // Yeşil
            UIColor(red: 0.20, green: 0.60, blue: 0.86, alpha: 1.0),  // Mavi
            UIColor(red: 0.95, green: 0.61, blue: 0.07, alpha: 1.0),  // Turuncu
            UIColor(red: 0.61, green: 0.35, blue: 0.71, alpha: 1.0),  // Mor
            UIColor(red: 0.17, green: 0.63, blue: 0.60, alpha: 1.0),  // Turkuaz
            UIColor(red: 0.91, green: 0.49, blue: 0.20, alpha: 1.0),  // Koyu Turuncu
            UIColor(red: 0.49, green: 0.18, blue: 0.56, alpha: 1.0),  // Koyu Mor
            UIColor(red: 0.20, green: 0.29, blue: 0.37, alpha: 1.0),  // Lacivert
            UIColor(red: 0.83, green: 0.18, blue: 0.18, alpha: 1.0),  // Bordo
            UIColor(red: 0.27, green: 0.54, blue: 0.18, alpha: 1.0),  // Koyu Yeşil
            UIColor(red: 0.35, green: 0.35, blue: 0.35, alpha: 1.0)   // Gri
        ]
        
        dataSet.valueTextColor = .black
        dataSet.valueFont = .systemFont(ofSize: 12)
        dataSet.valueFormatter = DefaultValueFormatter(decimals: 1)
        pieChartView.drawEntryLabelsEnabled = false
        
        let data = PieChartData(dataSet: dataSet)
        pieChartView.data = data
        pieChartView.notifyDataSetChanged()
    }
    
    private func updateLineChart(for category: String, stats: CategoryStats) {
        categoryLabel.text = String(format: LanguageManager.shared.localizedString(for: "category_details"), category)
        categoryLabel.isHidden = false
        lineChartView.isHidden = false
        
        let entries = [
            BarChartDataEntry(x: 0, y: Double(stats.correctAnswers)),
            BarChartDataEntry(x: 1, y: Double(stats.wrongAnswers)),
            BarChartDataEntry(x: 2, y: Double(stats.point))
        ]
        
        let dataSet = BarChartDataSet(entries: entries, label: "")
        
        // Farklı renkler atayalım
        dataSet.colors = [
            UIColor.systemGreen,  // Doğru cevaplar için yeşil
            UIColor.systemRed,    // Yanlış cevaplar için kırmızı
            UIColor.primaryPurple // Toplam puan için mor
        ]
        
        dataSet.valueTextColor = .black
        dataSet.valueFont = .systemFont(ofSize: 12)
        dataSet.valueFormatter = DefaultValueFormatter(decimals: 0)
        
        let data = BarChartData(dataSet: dataSet)
        data.barWidth = 0.7
        
        lineChartView.data = data
        lineChartView.notifyDataSetChanged()
        
        // Animasyonu yeniden tetikle
        lineChartView.animate(xAxisDuration: 0.5, yAxisDuration: 1.0)
    }
    
    // MARK: - ChartViewDelegate
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        if let pieEntry = entry as? PieChartDataEntry,
           let category = pieEntry.label,
           let stats = viewModel.categoryStats[category] {
            updateLineChart(for: category, stats: stats)
            // Force layout update to adjust scroll content size
            view.layoutIfNeeded()
        }
    }
    
    func chartValueNothingSelected(_ chartView: ChartViewBase) {
        categoryLabel.isHidden = true
        lineChartView.isHidden = true
        // Force layout update to adjust scroll content size
        view.layoutIfNeeded()
    }
    
    private func setupBindings() {
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.loadingIndicator.startAnimating()
                } else {
                    self?.loadingIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)
        
        viewModel.$totalPoints
            .receive(on: DispatchQueue.main)
            .sink { [weak self] points in
                self?.pointsValueLabel.text = "\(points)🏅"
            }
            .store(in: &cancellables)
        
        viewModel.$worldRank
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rank in
                self?.rankValueLabel.text = "🏆 \(rank)"
            }
            .store(in: &cancellables)
        
        viewModel.$categoryStats
            .receive(on: DispatchQueue.main)
            .sink { [weak self] stats in
                self?.updatePieChart(with: stats)
            }
            .store(in: &cancellables)
        
        viewModel.$error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                if let error = error {
                    self?.showLeaderboardError(error)
                }
            }
            .store(in: &cancellables)
        
        viewModel.$quizzesPlayed
            .receive(on: DispatchQueue.main)
            .sink { [weak self] quizzes in
                self?.quizzesValueLabel.text = "\(quizzes)"
                // Eğer quiz çözülmemişse noDataView'ı göster, statsView'ı gizle
                self?.noDataView.isHidden = quizzes > 0
                self?.statsView.isHidden = quizzes == 0
            }
            .store(in: &cancellables)
    }
    
    private func createTopUserCard(rank: Int) -> UIView {
        let cardView = UIView()
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 16
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 4
        cardView.layer.shadowOpacity = 0.1
        cardView.translatesAutoresizingMaskIntoConstraints = false
        
        let rankLabel = UILabel()
        rankLabel.text = "#\(rank)"
        rankLabel.font = rank == 1 ? .systemFont(ofSize: 24, weight: .bold) : .systemFont(ofSize: 20, weight: .bold)
        rankLabel.textAlignment = .center
        rankLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let avatarImageView = UIImageView()
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        // Birinci için daha büyük avatar
        let avatarSize = rank == 1 ? 90.0 : 70.0
        avatarImageView.layer.cornerRadius = avatarSize / 2
        avatarImageView.backgroundColor = .systemGray6
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        
        let nameLabel = UILabel()
        nameLabel.font = rank == 1 ? .systemFont(ofSize: 18, weight: .semibold) : .systemFont(ofSize: 16, weight: .semibold)
        nameLabel.textColor = .black
        nameLabel.textAlignment = .center
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = 0.5
        nameLabel.numberOfLines = 2
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let pointsLabel = UILabel()
        pointsLabel.font = rank == 1 ? .systemFont(ofSize: 16) : .systemFont(ofSize: 14)
        pointsLabel.textColor = .systemIndigo
        pointsLabel.textAlignment = .center
        pointsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        cardView.addSubview(rankLabel)
        cardView.addSubview(avatarImageView)
        cardView.addSubview(nameLabel)
        cardView.addSubview(pointsLabel)
        
        NSLayoutConstraint.activate([
            rankLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: rank == 1 ? 12 : 8),
            rankLabel.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            
            avatarImageView.topAnchor.constraint(equalTo: rankLabel.bottomAnchor, constant: rank == 1 ? 12 : 8),
            avatarImageView.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: avatarSize),
            avatarImageView.heightAnchor.constraint(equalToConstant: avatarSize),
            
            nameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: rank == 1 ? 12 : 8),
            nameLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 4),
            nameLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -4),
            
            pointsLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: rank == 1 ? 8 : 4),
            pointsLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 4),
            pointsLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -4),
            pointsLabel.bottomAnchor.constraint(lessThanOrEqualTo: cardView.bottomAnchor, constant: rank == 1 ? -12 : -8)
        ])
        
        // Tag'leri kullanarak daha sonra güncelleyebilmek için view'ları saklayalım
        rankLabel.tag = rank * 1000 + 1
        avatarImageView.tag = rank * 1000 + 2
        nameLabel.tag = rank * 1000 + 3
        pointsLabel.tag = rank * 1000 + 4
        
        return cardView
    }
    
    private func updateTopThreeCards() {
        guard leaderboardUsers.count >= 3 else { return }
        
        let rankColors = [
            1: UIColor(red: 1, green: 0.84, blue: 0, alpha: 1), // Gold
            2: UIColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 1), // Silver
            3: UIColor(red: 0.8, green: 0.5, blue: 0.2, alpha: 1) // Bronze
        ]
        
        for rank in 1...3 {
            let user = leaderboardUsers[rank - 1]
            let cardView = topThreeStackView.arrangedSubviews[rank == 1 ? 1 : rank == 2 ? 0 : 2]
            
            if let rankLabel = cardView.viewWithTag(rank * 1000 + 1) as? UILabel {
                rankLabel.text = "#\(rank)"
                rankLabel.textColor = rankColors[rank]
            }
            
            if let avatarImageView = cardView.viewWithTag(rank * 1000 + 2) as? UIImageView {
                if let avatarType = Avatar(rawValue: user.avatar) {
                    avatarImageView.image = avatarType.image
                    avatarImageView.backgroundColor = avatarType.backgroundColor
                }
            }
            
            if let nameLabel = cardView.viewWithTag(rank * 1000 + 3) as? UILabel {
                nameLabel.text = user.name
                
                let maxWidth = rank == 1 ? 120.0 : 100.0
                let currentFont = rank == 1 ? UIFont.systemFont(ofSize: 18, weight: .semibold) : UIFont.systemFont(ofSize: 16, weight: .semibold)
                let size = (user.name as NSString).size(withAttributes: [.font: currentFont])
                
                if size.width > maxWidth {
                    nameLabel.font = rank == 1 ? .systemFont(ofSize: 16, weight: .semibold) : .systemFont(ofSize: 14, weight: .semibold)
                }
            }
            
            if let pointsLabel = cardView.viewWithTag(rank * 1000 + 4) as? UILabel {
                pointsLabel.text = String(format: "%d %@", user.totalPoints, LanguageManager.shared.localizedString(for: "points"))
            }
        }
    }
} 
