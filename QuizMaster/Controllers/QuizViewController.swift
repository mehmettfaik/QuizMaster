import UIKit
import Combine

class QuizViewController: UIViewController {
    private let category: String
    private let difficulty: QuizDifficulty
    private let viewModel = QuizViewModel()
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?
    private var timeLeft: Int = 10
    
    private let progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.progressTintColor = .primaryPurple
        progress.trackTintColor = .systemGray5
        progress.layer.cornerRadius = 4
        progress.clipsToBounds = true
        progress.translatesAutoresizingMaskIntoConstraints = false
        return progress
    }()
    
    private let progressLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .primaryPurple
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let timerContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 30
        view.layer.borderWidth = 3
        view.layer.borderColor = UIColor.primaryPurple.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let timerLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .primaryPurple
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let questionContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .primaryPurple
        view.layer.cornerRadius = 20
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let questionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.textColor = .white
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let optionsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Next", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .primaryPurple
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 25
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // Constraint'leri saklayacağımız property'ler
    private var questionLabelTopToImageConstraint: NSLayoutConstraint!
    private var questionLabelTopToTimerConstraint: NSLayoutConstraint!
    
    init(category: String, difficulty: QuizDifficulty) {
        self.category = category
        self.difficulty = difficulty
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        viewModel.loadQuiz(category: category, difficulty: difficulty)
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .black
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(closeButton)
        view.addSubview(progressView)
        view.addSubview(progressLabel)
        view.addSubview(timerContainer)
        timerContainer.addSubview(timerLabel)
        view.addSubview(questionContainer)
        questionContainer.addSubview(questionLabel)
        view.addSubview(optionsStackView)
        view.addSubview(nextButton)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
            
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            progressView.leadingAnchor.constraint(equalTo: closeButton.trailingAnchor, constant: 16),
            progressView.trailingAnchor.constraint(equalTo: progressLabel.leadingAnchor, constant: -8),
            progressView.heightAnchor.constraint(equalToConstant: 8),
            progressView.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            
            progressLabel.centerYAnchor.constraint(equalTo: progressView.centerYAnchor),
            progressLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            progressLabel.widthAnchor.constraint(equalToConstant: 50),
            
            timerContainer.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 32),
            timerContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            timerContainer.widthAnchor.constraint(equalToConstant: 60),
            timerContainer.heightAnchor.constraint(equalToConstant: 60),
            
            timerLabel.centerXAnchor.constraint(equalTo: timerContainer.centerXAnchor),
            timerLabel.centerYAnchor.constraint(equalTo: timerContainer.centerYAnchor),
            
            questionContainer.topAnchor.constraint(equalTo: timerContainer.bottomAnchor, constant: 32),
            questionContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            questionContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            questionLabel.topAnchor.constraint(equalTo: questionContainer.topAnchor, constant: 24),
            questionLabel.leadingAnchor.constraint(equalTo: questionContainer.leadingAnchor, constant: 24),
            questionLabel.trailingAnchor.constraint(equalTo: questionContainer.trailingAnchor, constant: -24),
            questionLabel.bottomAnchor.constraint(equalTo: questionContainer.bottomAnchor, constant: -24),
            
            optionsStackView.topAnchor.constraint(equalTo: questionContainer.bottomAnchor, constant: 32),
            optionsStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            optionsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            nextButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            nextButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
    }
    
    private func setupBindings() {
        viewModel.$currentQuestion
            .receive(on: DispatchQueue.main)
            .sink { [weak self] question in
                self?.updateUI(with: question)
            }
            .store(in: &cancellables)
        
        viewModel.$isFinished
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isFinished in
                if isFinished {
                    self?.showResults()
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateUI(with question: Question?) {
        guard let question = question else { return }
        
        // Clear existing option buttons
        optionsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Update progress
        let progress = Float(viewModel.currentQuestionIndex) / Float(viewModel.totalQuestions)
        progressView.setProgress(progress, animated: true)
        progressLabel.text = "\(viewModel.currentQuestionIndex + 1)/\(viewModel.totalQuestions)"
        
        // Update question text
        questionLabel.text = question.text
        
        // Check if options have images
        if let optionImages = question.optionImages, !optionImages.isEmpty {
            // Create 2x2 grid layout for image options
            let gridContainer = UIStackView()
            gridContainer.axis = .vertical
            gridContainer.spacing = 16
            gridContainer.distribution = .fillEqually
            
            let topRow = UIStackView()
            topRow.axis = .horizontal
            topRow.spacing = 16
            topRow.distribution = .fillEqually
            
            let bottomRow = UIStackView()
            bottomRow.axis = .horizontal
            bottomRow.spacing = 16
            bottomRow.distribution = .fillEqually
            
            gridContainer.addArrangedSubview(topRow)
            gridContainer.addArrangedSubview(bottomRow)
            optionsStackView.addArrangedSubview(gridContainer)
            
            // Add options to grid
            for (index, option) in question.options.enumerated() {
                let containerView = UIView()
                containerView.backgroundColor = .white
                containerView.layer.cornerRadius = 12
                containerView.layer.borderWidth = 1
                containerView.layer.borderColor = UIColor.systemGray4.cgColor
                containerView.translatesAutoresizingMaskIntoConstraints = false
                
                let imageView = UIImageView()
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                imageView.layer.cornerRadius = 12
                imageView.translatesAutoresizingMaskIntoConstraints = false
                imageView.isUserInteractionEnabled = false
                
                if index < optionImages.count {
                    imageView.image = UIImage(named: optionImages[index])
                }
                
                let button = UIButton(type: .system)
                button.backgroundColor = .clear
                button.setTitle(option, for: .normal)
                button.setTitle("", for: .normal) // Hide the title
                button.tag = index
                button.addTarget(self, action: #selector(optionButtonTapped(_:)), for: .touchUpInside)
                button.translatesAutoresizingMaskIntoConstraints = false
                
                containerView.addSubview(imageView)
                containerView.addSubview(button)
                
                NSLayoutConstraint.activate([
                    imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
                    imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                    imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                    imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                    
                    button.topAnchor.constraint(equalTo: containerView.topAnchor),
                    button.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                    button.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                    button.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
                ])
                
                if index < 2 {
                    topRow.addArrangedSubview(containerView)
                } else {
                    bottomRow.addArrangedSubview(containerView)
                }
            }
            
            // Set grid container height
            gridContainer.heightAnchor.constraint(equalToConstant: 280).isActive = true
            
        } else {
            // Create regular text options
            for option in question.options {
                let containerView = UIView()
                containerView.backgroundColor = .white
                containerView.layer.cornerRadius = 12
                containerView.layer.borderWidth = 1
                containerView.layer.borderColor = UIColor.systemGray4.cgColor
                containerView.translatesAutoresizingMaskIntoConstraints = false
                
                let button = UIButton(type: .system)
                button.setTitle(option, for: .normal)
                button.setTitleColor(.black, for: .normal)
                button.titleLabel?.font = .systemFont(ofSize: 16)
                button.contentHorizontalAlignment = .left
                button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
                button.addTarget(self, action: #selector(optionButtonTapped(_:)), for: .touchUpInside)
                button.translatesAutoresizingMaskIntoConstraints = false
                
                containerView.addSubview(button)
                
                NSLayoutConstraint.activate([
                    containerView.heightAnchor.constraint(equalToConstant: 50),
                    button.topAnchor.constraint(equalTo: containerView.topAnchor),
                    button.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                    button.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                    button.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
                ])
                
                optionsStackView.addArrangedSubview(containerView)
            }
        }
        
        // Start timer
        startTimer()
    }
    
    private func startTimer() {
        timeLeft = 10
        updateTimerLabel()
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.timeLeft -= 1
            self?.updateTimerLabel()
            
            if self?.timeLeft == 0 {
                self?.timer?.invalidate()
                self?.handleTimeUp()
            }
        }
    }
    
    private func updateTimerLabel() {
        timerLabel.text = "\(timeLeft)"
        if timeLeft <= 3 {
            timerLabel.textColor = .systemRed
        } else {
            timerLabel.textColor = .primaryPurple
        }
    }
    
    private func handleTimeUp() {
        viewModel.answerQuestion(nil)
    }
    
    @objc private func optionButtonTapped(_ sender: UIButton) {
        guard let currentQuestion = viewModel.currentQuestion else { return }
        
        var selectedAnswer: String
        var selectedIndex: Int
        
        if let optionImages = currentQuestion.optionImages, !optionImages.isEmpty {
            // For image options, use the index
            selectedIndex = sender.tag
            selectedAnswer = currentQuestion.options[selectedIndex]
        } else {
            // For text options, use the button title
            guard let buttonTitle = sender.title(for: .normal) else { return }
            selectedAnswer = buttonTitle
            selectedIndex = currentQuestion.options.firstIndex(of: buttonTitle) ?? 0
        }
        
        timer?.invalidate()
        viewModel.answerQuestion(selectedAnswer)
        
        // Highlight correct and wrong answers
        if let optionImages = currentQuestion.optionImages, !optionImages.isEmpty {
            // Handle image options
            if let gridContainer = optionsStackView.arrangedSubviews.first as? UIStackView {
                var allOptionViews: [UIView] = []
                
                // Collect all option views in order
                for rowStack in gridContainer.arrangedSubviews {
                    guard let row = rowStack as? UIStackView else { continue }
                    allOptionViews.append(contentsOf: row.arrangedSubviews)
                }
                
                // Find correct answer index
                let correctIndex = currentQuestion.options.firstIndex(of: currentQuestion.correctAnswer) ?? -1
                
                // Update UI for each option
                for (index, optionContainer) in allOptionViews.enumerated() {
                    if index == correctIndex {
                        // Correct answer
                        optionContainer.layer.borderWidth = 3
                        optionContainer.layer.borderColor = UIColor.systemGreen.cgColor
                    } else if index == selectedIndex && index != correctIndex {
                        // Wrong answer
                        optionContainer.layer.borderWidth = 3
                        optionContainer.layer.borderColor = UIColor.systemRed.cgColor
                    }
                    
                    // Disable button
                    if let button = optionContainer.subviews.last as? UIButton {
                        button.isEnabled = false
                    }
                }
            }
        } else {
            // Handle text options
            optionsStackView.arrangedSubviews.forEach { view in
                guard let containerView = view as? UIView,
                      let button = containerView.subviews.first(where: { $0 is UIButton }) as? UIButton,
                      let title = button.title(for: .normal) else { return }
                
                if title == currentQuestion.correctAnswer {
                    containerView.backgroundColor = .systemGreen.withAlphaComponent(0.3)
                    button.setTitleColor(.systemGreen, for: .normal)
                } else if title == selectedAnswer && title != currentQuestion.correctAnswer {
                    containerView.backgroundColor = .systemRed.withAlphaComponent(0.3)
                    button.setTitleColor(.systemRed, for: .normal)
                }
                button.isEnabled = false
            }
        }
        
        // Wait for a moment before moving to the next question
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.viewModel.nextQuestion()
        }
    }
    
    private func showResults() {
        let resultsVC = QuizResultsViewController(score: viewModel.score, totalQuestions: viewModel.totalQuestions)
        resultsVC.modalPresentationStyle = .fullScreen
        present(resultsVC, animated: true)
    }
    
    @objc private func closeButtonTapped() {
        timer?.invalidate()
        dismiss(animated: true)
    }
    
    deinit {
        timer?.invalidate()
    }
} 