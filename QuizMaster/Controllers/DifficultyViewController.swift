import UIKit

class DifficultyViewController: UIViewController {
    private let category: String
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 20
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 10
        view.layer.shadowOpacity = 0.1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 35, weight: .bold)
        label.textColor = .primaryPurple
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Choose your challenge level"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor.darkGray
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 35
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private lazy var easyButton: UIButton = createDifficultyButton(
        title: "Easy",
        color: UIColor.systemGreen.withAlphaComponent(0.9),
        icon: "💫",
        description: "Perfect for beginners"
    )
    
    private lazy var mediumButton: UIButton = createDifficultyButton(
        title: "Medium",
        color: UIColor(red: 109/255, green: 109/255, blue: 109/255, alpha: 1),
        icon: "🌟",
        description: "For experienced players"
    )
    
    private lazy var hardButton: UIButton = createDifficultyButton(
        title: "Hard",
        color: UIColor(red: 230/255, green: 57/255, blue: 70/255, alpha: 1),
        icon: "⚡️",
        description: "Test your expertise"
    )
    
    init(category: String) {
        self.category = category
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        animateUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .primaryPurple
        
        titleLabel.text = category
        
        view.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(subtitleLabel)
        containerView.addSubview(stackView)
        
        let backButton = UIButton(type: .system)
        backButton.backgroundColor = .primaryPurple
        backButton.layer.cornerRadius = 18
        backButton.setImage(UIImage(systemName: "chevron.left")?.withRenderingMode(.alwaysTemplate), for: .normal)
        backButton.tintColor = .white
        backButton.imageView?.contentMode = .scaleAspectFit
        backButton.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(backButton)
        
        stackView.addArrangedSubview(easyButton)
        stackView.addArrangedSubview(mediumButton)
        stackView.addArrangedSubview(hardButton)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            backButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            backButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 36),
            backButton.heightAnchor.constraint(equalToConstant: 36),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 80),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            stackView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            easyButton.heightAnchor.constraint(equalToConstant: 100),
            mediumButton.heightAnchor.constraint(equalToConstant: 100),
            hardButton.heightAnchor.constraint(equalToConstant: 100)
        ])
        
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
    }
    
    private func createDifficultyButton(title: String, color: UIColor, icon: String, description: String) -> UIButton {
        let button = UIButton(type: .custom)
        button.accessibilityIdentifier = title
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.alignment = .center
        stackView.isUserInteractionEnabled = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let iconLabel = UILabel()
        iconLabel.text = icon
        iconLabel.font = .systemFont(ofSize: 30)
        iconLabel.widthAnchor.constraint(equalToConstant: 40).isActive = true
        iconLabel.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        let textStackView = UIStackView()
        textStackView.axis = .vertical
        textStackView.spacing = 4
        textStackView.isUserInteractionEnabled = false
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = .white
        
        let descriptionLabel = UILabel()
        descriptionLabel.text = description
        descriptionLabel.font = .systemFont(ofSize: 14, weight: .regular)
        descriptionLabel.textColor = .white.withAlphaComponent(0.8)
        
        textStackView.addArrangedSubview(titleLabel)
        textStackView.addArrangedSubview(descriptionLabel)
        
        stackView.addArrangedSubview(iconLabel)
        stackView.addArrangedSubview(textStackView)
        
        button.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -20),
            stackView.centerYAnchor.constraint(equalTo: button.centerYAnchor)
        ])
        
        button.backgroundColor = color
        button.layer.cornerRadius = 20
        button.layer.shadowColor = color.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 8
        button.layer.shadowOpacity = 0.3
        
        button.addTarget(self, action: #selector(difficultyButtonTapped(_:)), for: .touchUpInside)
        return button
    }
    
    private func animateUI() {
        let buttons = [easyButton, mediumButton, hardButton]
        let originalTransform = CGAffineTransform(translationX: view.bounds.width, y: 0)
        
        buttons.forEach { button in
            button.transform = originalTransform
            button.alpha = 0
        }
        
        UIView.animate(withDuration: 0.5, delay: 0.2, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            self.titleLabel.transform = .identity
            self.titleLabel.alpha = 1
        }
        
        for (index, button) in buttons.enumerated() {
            UIView.animate(withDuration: 0.7, delay: Double(index) * 0.15 + 0.3, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
                button.transform = .identity
                button.alpha = 1
            }
        }
    }
    
    @objc private func difficultyButtonTapped(_ sender: UIButton) {
        guard let difficulty = sender.accessibilityIdentifier,
              let difficultyEnum = QuizDifficulty(rawValue: difficulty) else { return }
        
        UIView.animate(withDuration: 0.1, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            sender.transform = .identity
            let quizVC = QuizViewController(category: self.category, difficulty: difficultyEnum)
            quizVC.modalPresentationStyle = .fullScreen
            self.present(quizVC, animated: true)
        }
    }
    
    @objc private func backButtonTapped() {
        dismiss(animated: true)
    }
} 
