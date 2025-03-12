import UIKit
import Combine

class StatsViewController: UIViewController {
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
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
            statsView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)
        ])
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
