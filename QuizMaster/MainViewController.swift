import UIKit

class MainViewController: UIViewController {
    
    // MARK: - Properties
    private let viewModel = MainViewModel()
    
    // MARK: - UI Components
    private let welcomeLabel: UILabel = {
        let label = UILabel()
        label.text = "Welcome to QuizMaster"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let startButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Start Quiz", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupBindings()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "QuizMaster"
        
        view.addSubview(welcomeLabel)
        view.addSubview(startButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            welcomeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            welcomeLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            
            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startButton.topAnchor.constraint(equalTo: welcomeLabel.bottomAnchor, constant: 30),
            startButton.widthAnchor.constraint(equalToConstant: 200),
            startButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupBindings() {
        startButton.addTarget(self, action: #selector(startButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func startButtonTapped() {
        let quizListViewController = QuizListViewController()
        navigationController?.pushViewController(quizListViewController, animated: true)
    }
} 