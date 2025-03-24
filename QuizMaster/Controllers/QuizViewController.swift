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
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let timerLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .black
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let circularProgressLayer = CAShapeLayer()
    private let trackLayer = CAShapeLayer()
    
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
    
    private let askGPTButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("QuizGPT'ye sor", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .primaryPurple
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 25
        button.isHidden = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Next", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemGray5
        button.setTitleColor(.black, for: .normal)
        button.layer.cornerRadius = 25
        button.isHidden = true
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
        closeButton.setImage(UIImage(systemName: "xmark")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        ), for: .normal)
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        closeButton.tintColor = .black
        closeButton.layer.cornerRadius = 15
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(closeButton)
        view.addSubview(progressView)
        view.addSubview(progressLabel)
        view.addSubview(timerContainer)
        timerContainer.addSubview(timerLabel)
        view.addSubview(questionContainer)
        questionContainer.addSubview(questionLabel)
        view.addSubview(optionsStackView)
        view.addSubview(askGPTButton)
        view.addSubview(nextButton)
        
        setupTimerUI()
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),
            
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
            
            askGPTButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            askGPTButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            askGPTButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5, constant: -40),
            askGPTButton.heightAnchor.constraint(equalToConstant: 50),
            
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            nextButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.3, constant: -40),
            nextButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        askGPTButton.addTarget(self, action: #selector(askGPTButtonTapped), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
    }
    
    private func setupTimerUI() {
        // Setup track layer
        let circularPath = UIBezierPath(arcCenter: CGPoint(x: 30, y: 30),
                                      radius: 30,
                                      startAngle: -CGFloat.pi / 2,
                                      endAngle: 2 * CGFloat.pi - CGFloat.pi / 2,
                                      clockwise: true)
        
        trackLayer.path = circularPath.cgPath
        trackLayer.strokeColor = UIColor.systemGray4.cgColor
        trackLayer.lineWidth = 6
        trackLayer.fillColor = UIColor.clear.cgColor
        timerContainer.layer.addSublayer(trackLayer)
        
        // Setup progress layer
        circularProgressLayer.path = circularPath.cgPath
        circularProgressLayer.strokeColor = UIColor.primaryPurple.cgColor
        circularProgressLayer.lineWidth = 6
        circularProgressLayer.fillColor = UIColor.clear.cgColor
        circularProgressLayer.lineCap = .round
        circularProgressLayer.strokeEnd = 1.0
        timerContainer.layer.addSublayer(circularProgressLayer)
    }
    
    private func setupBindings() {
        viewModel.$currentQuestion
            .receive(on: DispatchQueue.main)
            .sink { [weak self] question in
                self?.updateUI(with: question)
                // Hide buttons when new question appears
                self?.askGPTButton.isHidden = true
                self?.nextButton.isHidden = true
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
        
        // Calculate progress and color
        let progress = CGFloat(timeLeft) / 10.0
        let color = UIColor.interpolate(from: .systemGray4, to: .primaryPurple, with: progress)
        
        // Update progress layer
        circularProgressLayer.strokeEnd = progress
        circularProgressLayer.strokeColor = color.cgColor
        
        // Update label color
        if timeLeft <= 3 {
            timerLabel.textColor = .systemRed
        } else {
            timerLabel.textColor = .black
        }
    }
    
    private func handleTimeUp() {
        viewModel.answerQuestion(nil)
        // Show Ask GPT and Next buttons when time runs out
        askGPTButton.isHidden = false
        nextButton.isHidden = false
        
        // Highlight correct answer in green
        guard let currentQuestion = viewModel.currentQuestion else { return }
        
        if let optionImages = currentQuestion.optionImages, !optionImages.isEmpty {
            if let gridContainer = optionsStackView.arrangedSubviews.first as? UIStackView {
                var allOptionViews: [UIView] = []
                
                for rowStack in gridContainer.arrangedSubviews {
                    guard let row = rowStack as? UIStackView else { continue }
                    allOptionViews.append(contentsOf: row.arrangedSubviews)
                }
                
                let correctIndex = currentQuestion.options.firstIndex(of: currentQuestion.correctAnswer) ?? -1
                
                for (index, optionContainer) in allOptionViews.enumerated() {
                    if index == correctIndex {
                        optionContainer.layer.borderWidth = 3
                        optionContainer.layer.borderColor = UIColor.systemGreen.cgColor
                    }
                    
                    if let button = optionContainer.subviews.last as? UIButton {
                        button.isEnabled = false
                    }
                }
            }
        } else {
            optionsStackView.arrangedSubviews.forEach { view in
                guard let containerView = view as? UIView,
                      let button = containerView.subviews.first(where: { $0 is UIButton }) as? UIButton,
                      let title = button.title(for: .normal) else { return }
                
                if title == currentQuestion.correctAnswer {
                    containerView.backgroundColor = .systemGreen.withAlphaComponent(0.3)
                    button.setTitleColor(.systemGreen, for: .normal)
                }
                button.isEnabled = false
            }
        }
    }
    
    @objc private func optionButtonTapped(_ sender: UIButton) {
        guard let currentQuestion = viewModel.currentQuestion else { return }
        
        var selectedAnswer: String
        var selectedIndex: Int
        
        if let optionImages = currentQuestion.optionImages, !optionImages.isEmpty {
            selectedIndex = sender.tag
            selectedAnswer = currentQuestion.options[selectedIndex]
        } else {
            guard let buttonTitle = sender.title(for: .normal) else { return }
            selectedAnswer = buttonTitle
            selectedIndex = currentQuestion.options.firstIndex(of: buttonTitle) ?? 0
        }
        
        timer?.invalidate()
        viewModel.answerQuestion(selectedAnswer)
        
        // Highlight correct and wrong answers
        if let optionImages = currentQuestion.optionImages, !optionImages.isEmpty {
            if let gridContainer = optionsStackView.arrangedSubviews.first as? UIStackView {
                var allOptionViews: [UIView] = []
                
                for rowStack in gridContainer.arrangedSubviews {
                    guard let row = rowStack as? UIStackView else { continue }
                    allOptionViews.append(contentsOf: row.arrangedSubviews)
                }
                
                let correctIndex = currentQuestion.options.firstIndex(of: currentQuestion.correctAnswer) ?? -1
                
                for (index, optionContainer) in allOptionViews.enumerated() {
                    if index == correctIndex {
                        optionContainer.layer.borderWidth = 3
                        optionContainer.layer.borderColor = UIColor.systemGreen.cgColor
                    } else if index == selectedIndex && index != correctIndex {
                        optionContainer.layer.borderWidth = 3
                        optionContainer.layer.borderColor = UIColor.systemRed.cgColor
                    }
                    
                    if let button = optionContainer.subviews.last as? UIButton {
                        button.isEnabled = false
                    }
                }
            }
        } else {
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
        
        // Show Ask GPT and Next buttons if answer is wrong
        let isCorrect = selectedAnswer == currentQuestion.correctAnswer
        askGPTButton.isHidden = isCorrect
        nextButton.isHidden = isCorrect
        
        // Wait for a moment before moving to the next question if correct
        if isCorrect {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.viewModel.nextQuestion()
            }
        }
    }
    
    @objc private func askGPTButtonTapped() {
        guard let currentQuestion = viewModel.currentQuestion else { return }
        
        let chatVC = ChatViewController()
        chatVC.modalPresentationStyle = .pageSheet
        
        // Soruyu ve kullanıcının cevabını hazırla
        let questionText = "Question: \(currentQuestion.text)\n" +
                         "Correct Answer: \(currentQuestion.correctAnswer)\n" +
                         "Why is this answer correct and the others incorrect? Can you explain in detail?"
        
        // ChatViewController'a soruyu gönder
        chatVC.presetMessage = questionText
        
        present(chatVC, animated: true)
    }
    
    @objc private func nextButtonTapped() {
        viewModel.nextQuestion()
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

extension UIColor {
    static func interpolate(from: UIColor, to: UIColor, with progress: CGFloat) -> UIColor {
        var fromRed: CGFloat = 0
        var fromGreen: CGFloat = 0
        var fromBlue: CGFloat = 0
        var fromAlpha: CGFloat = 0
        from.getRed(&fromRed, green: &fromGreen, blue: &fromBlue, alpha: &fromAlpha)
        
        var toRed: CGFloat = 0
        var toGreen: CGFloat = 0
        var toBlue: CGFloat = 0
        var toAlpha: CGFloat = 0
        to.getRed(&toRed, green: &toGreen, blue: &toBlue, alpha: &toAlpha)
        
        let red = fromRed + (toRed - fromRed) * progress
        let green = fromGreen + (toGreen - fromGreen) * progress
        let blue = fromBlue + (toBlue - fromBlue) * progress
        let alpha = fromAlpha + (toAlpha - fromAlpha) * progress
        
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
} 
