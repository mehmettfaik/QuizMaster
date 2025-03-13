import UIKit
import DGCharts
import Combine
import Charts

class StatsViewController: UIViewController, ChartViewDelegate {
    private let viewModel = UserViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .primaryPurple
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let pointsLabel: UILabel = {
        let label = UILabel()
        label.text = "POINTS"
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
    
    private let rankLabel: UILabel = {
        let label = UILabel()
        label.text = "WORLD RANK"
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        setupPieChart()
        setupLineChart()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadUserProfile()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(headerView)
        headerView.addSubview(pointsLabel)
        headerView.addSubview(pointsValueLabel)
        headerView.addSubview(rankLabel)
        headerView.addSubview(rankValueLabel)
        headerView.addSubview(loadingIndicator)
        
        view.addSubview(statsView)
        statsView.addSubview(pieChartView)
        statsView.addSubview(categoryLabel)
        statsView.addSubview(lineChartView)
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 120),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            pointsLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            pointsLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            pointsValueLabel.leadingAnchor.constraint(equalTo: pointsLabel.leadingAnchor),
            pointsValueLabel.topAnchor.constraint(equalTo: pointsLabel.bottomAnchor, constant: 4),
            
            rankLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            rankLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            rankValueLabel.trailingAnchor.constraint(equalTo: rankLabel.trailingAnchor),
            rankValueLabel.topAnchor.constraint(equalTo: rankLabel.bottomAnchor, constant: 4),
            
            statsView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 20),
            statsView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statsView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            statsView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            
            pieChartView.topAnchor.constraint(equalTo: statsView.topAnchor, constant: 20),
            pieChartView.leadingAnchor.constraint(equalTo: statsView.leadingAnchor, constant: 20),
            pieChartView.trailingAnchor.constraint(equalTo: statsView.trailingAnchor, constant: -20),
            pieChartView.heightAnchor.constraint(equalTo: pieChartView.widthAnchor),
            
            categoryLabel.topAnchor.constraint(equalTo: pieChartView.bottomAnchor, constant: 20),
            categoryLabel.leadingAnchor.constraint(equalTo: statsView.leadingAnchor, constant: 20),
            categoryLabel.trailingAnchor.constraint(equalTo: statsView.trailingAnchor, constant: -20),
            
            lineChartView.topAnchor.constraint(equalTo: categoryLabel.bottomAnchor, constant: 10),
            lineChartView.leadingAnchor.constraint(equalTo: statsView.leadingAnchor, constant: 20),
            lineChartView.trailingAnchor.constraint(equalTo: statsView.trailingAnchor, constant: -20),
            lineChartView.heightAnchor.constraint(equalToConstant: 200)
        ])
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
        xAxis.valueFormatter = IndexAxisValueFormatter(values: ["Doğru", "Yanlış", "Puan"])
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
        
        let dataSet = PieChartDataSet(entries: entries, label: "Başarı Oranları (%)")
        dataSet.colors = ChartColorTemplates.material()
        dataSet.valueTextColor = .black
        dataSet.valueFont = .systemFont(ofSize: 12)
        dataSet.valueFormatter = DefaultValueFormatter(decimals: 1)
        
        let data = PieChartData(dataSet: dataSet)
        pieChartView.data = data
        pieChartView.notifyDataSetChanged()
    }
    
    private func updateLineChart(for category: String, stats: CategoryStats) {
        categoryLabel.text = "\(category) Detayları"
        categoryLabel.isHidden = false
        lineChartView.isHidden = false
        
        let entries = [
            BarChartDataEntry(x: 0, y: Double(stats.correctAnswers)),
            BarChartDataEntry(x: 1, y: Double(stats.wrongAnswers)),
            BarChartDataEntry(x: 2, y: Double(stats.totalPoints))
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
        }
    }
    
    func chartValueNothingSelected(_ chartView: ChartViewBase) {
        categoryLabel.isHidden = true
        lineChartView.isHidden = true
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
                self?.pointsValueLabel.text = "\(points)"
            }
            .store(in: &cancellables)
        
        viewModel.$worldRank
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rank in
                self?.rankValueLabel.text = "#\(rank)"
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
                    self?.showErrorAlert(error)
                }
            }
            .store(in: &cancellables)
    }
} 
