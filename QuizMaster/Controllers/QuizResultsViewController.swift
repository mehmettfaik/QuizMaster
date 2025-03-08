import UIKit

class QuizResultsViewController: UIViewController {
    private let score: Int
    private let totalQuestions: Int
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 20
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Quiz Completed!"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .primaryPurple
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let scoreLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 48, weight: .bold)
        label.textColor = .primaryPurple
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18)
        label.textColor = .gray
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let homeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Return to Home", for: .normal)
        button.backgroundColor = .primaryPurple
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    init(score: Int, totalQuestions: Int) {
        self.score = score
        self.totalQuestions = totalQuestions
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(scoreLabel)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(homeButton)
        
        NSLayoutConstraint.activate([
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            scoreLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            scoreLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            descriptionLabel.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: 20),
            descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            homeButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 40),
            homeButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            homeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            homeButton.heightAnchor.constraint(equalToConstant: 50),
            homeButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -40)
        ])
        
        containerView.addShadow(opacity: 0.1, radius: 10, offset: CGSize(width: 0, height: 5))
        homeButton.addTarget(self, action: #selector(homeButtonTapped), for: .touchUpInside)
    }
    
    private func updateUI() {
        scoreLabel.text = "\(score) points"
        
        let percentage = Double(score) / Double(totalQuestions * 10) * 100
        var description = ""
        
        switch percentage {
        case 90...100:
            description = "Excellent! You're a quiz master! 🏆"
        case 70..<90:
            description = "Great job! Keep it up! 🌟"
        case 50..<70:
            description = "Good effort! Room for improvement! 💪"
        default:
            description = "Don't give up! Try again! 🎯"
        }
        
        descriptionLabel.text = description
    }
    
    @objc private func homeButtonTapped() {
        // Dismiss all the way back to home
        view.window?.rootViewController?.dismiss(animated: true)
    }
} 