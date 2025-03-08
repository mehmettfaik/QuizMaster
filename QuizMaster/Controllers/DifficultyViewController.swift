import UIKit

class DifficultyViewController: UIViewController {
    private let category: String
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .primaryPurple
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private lazy var easyButton: UIButton = createDifficultyButton(title: "Easy", color: .systemGreen)
    private lazy var mediumButton: UIButton = createDifficultyButton(title: "Medium", color: .systemOrange)
    private lazy var hardButton: UIButton = createDifficultyButton(title: "Hard", color: .systemRed)
    
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
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        titleLabel.text = "Select Difficulty for \(category)"
        
        view.addSubview(titleLabel)
        view.addSubview(stackView)
        
        stackView.addArrangedSubview(easyButton)
        stackView.addArrangedSubview(mediumButton)
        stackView.addArrangedSubview(hardButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            easyButton.heightAnchor.constraint(equalToConstant: 60),
            mediumButton.heightAnchor.constraint(equalToConstant: 60),
            hardButton.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .primaryPurple
        backButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backButton)
        
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
    }
    
    private func createDifficultyButton(title: String, color: UIColor) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.backgroundColor = color
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(difficultyButtonTapped(_:)), for: .touchUpInside)
        return button
    }
    
    @objc private func difficultyButtonTapped(_ sender: UIButton) {
        guard let difficulty = sender.title(for: .normal),
              let difficultyEnum = QuizDifficulty(rawValue: difficulty) else { return }
        
        let quizVC = QuizViewController(category: category, difficulty: difficultyEnum)
        quizVC.modalPresentationStyle = .fullScreen
        present(quizVC, animated: true)
    }
    
    @objc private func backButtonTapped() {
        dismiss(animated: true)
    }
} 