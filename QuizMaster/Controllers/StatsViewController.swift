import UIKit

class StatsViewController: UIViewController {
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .primaryPurple
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let pointsLabel: UILabel = {
        let label = UILabel()
        label.text = "POINTS"
        label.textColor = .white
        label.font = .systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let pointsValueLabel: UILabel = {
        let label = UILabel()
        label.text = "590"
        label.textColor = .white
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let rankLabel: UILabel = {
        let label = UILabel()
        label.text = "WORLD RANK"
        label.textColor = .white
        label.font = .systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let rankValueLabel: UILabel = {
        let label = UILabel()
        label.text = "#1,438"
        label.textColor = .white
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let segmentedControl: UISegmentedControl = {
        let items = ["Badge", "Stats", "Details"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 1
        control.selectedSegmentTintColor = .primaryPurple
        control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        control.setTitleTextAttributes([.foregroundColor: UIColor.primaryPurple], for: .normal)
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private let statsView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 20
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let periodControl: UISegmentedControl = {
        let items = ["Monthly", "Weekly", "Daily"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.selectedSegmentTintColor = .primaryPurple
        control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        control.setTitleTextAttributes([.foregroundColor: UIColor.primaryPurple], for: .normal)
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private let quizPlayedLabel: UILabel = {
        let label = UILabel()
        label.text = "You have played a total\n24 quizzes this month!"
        label.numberOfLines = 2
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 18)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let progressView: UIView = {
        let view = UIView()
        view.backgroundColor = .backgroundPurple
        view.layer.cornerRadius = 50
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let progressLabel: UILabel = {
        let label = UILabel()
        label.text = "37/50\nquiz played"
        label.numberOfLines = 2
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let statsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(headerView)
        headerView.addSubview(pointsLabel)
        headerView.addSubview(pointsValueLabel)
        headerView.addSubview(rankLabel)
        headerView.addSubview(rankValueLabel)
        
        view.addSubview(segmentedControl)
        view.addSubview(statsView)
        
        statsView.addSubview(periodControl)
        statsView.addSubview(quizPlayedLabel)
        statsView.addSubview(progressView)
        progressView.addSubview(progressLabel)
        statsView.addSubview(statsStackView)
        
        // Add stat items
        let quizSolved = createStatItem(value: "29", title: "Quiz Solved")
        let quizWon = createStatItem(value: "21", title: "Quiz Won")
        statsStackView.addArrangedSubview(quizSolved)
        statsStackView.addArrangedSubview(quizWon)
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 120),
            
            pointsLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            pointsLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            pointsValueLabel.leadingAnchor.constraint(equalTo: pointsLabel.leadingAnchor),
            pointsValueLabel.topAnchor.constraint(equalTo: pointsLabel.bottomAnchor, constant: 4),
            
            rankLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            rankLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            rankValueLabel.trailingAnchor.constraint(equalTo: rankLabel.trailingAnchor),
            rankValueLabel.topAnchor.constraint(equalTo: rankLabel.bottomAnchor, constant: 4),
            
            segmentedControl.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 20),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            statsView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 20),
            statsView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statsView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            statsView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            
            periodControl.topAnchor.constraint(equalTo: statsView.topAnchor, constant: 20),
            periodControl.leadingAnchor.constraint(equalTo: statsView.leadingAnchor, constant: 20),
            periodControl.trailingAnchor.constraint(equalTo: statsView.trailingAnchor, constant: -20),
            
            quizPlayedLabel.topAnchor.constraint(equalTo: periodControl.bottomAnchor, constant: 30),
            quizPlayedLabel.centerXAnchor.constraint(equalTo: statsView.centerXAnchor),
            
            progressView.topAnchor.constraint(equalTo: quizPlayedLabel.bottomAnchor, constant: 30),
            progressView.centerXAnchor.constraint(equalTo: statsView.centerXAnchor),
            progressView.widthAnchor.constraint(equalToConstant: 100),
            progressView.heightAnchor.constraint(equalToConstant: 100),
            
            progressLabel.centerXAnchor.constraint(equalTo: progressView.centerXAnchor),
            progressLabel.centerYAnchor.constraint(equalTo: progressView.centerYAnchor),
            
            statsStackView.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 30),
            statsStackView.leadingAnchor.constraint(equalTo: statsView.leadingAnchor, constant: 20),
            statsStackView.trailingAnchor.constraint(equalTo: statsView.trailingAnchor, constant: -20),
            statsStackView.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    private func createStatItem(value: String, title: String) -> UIView {
        let container = UIView()
        container.backgroundColor = .backgroundPurple
        container.layer.cornerRadius = 12
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 24, weight: .bold)
        valueLabel.textColor = .primaryPurple
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.textColor = .gray
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(valueLabel)
        container.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            valueLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            valueLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            
            titleLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 4)
        ])
        
        return container
    }
} 