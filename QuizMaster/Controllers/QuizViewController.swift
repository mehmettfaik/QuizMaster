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
        view.backgroundColor = .white
        view.layer.cornerRadius = 20
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 12
        view.layer.shadowOpacity = 0.1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let questionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 22, weight: .semibold)
        label.textColor = .primaryPurple
        label.numberOfLines = 0
        label.textAlignment = .left
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
        button.setTitle(LanguageManager.shared.localizedString(for: "ask_ai"), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .white
        button.setTitleColor(.primaryPurple, for: .normal)
        button.layer.cornerRadius = 25
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.primaryPurple.cgColor
        button.isHidden = true
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Gölge efekti
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 8
        button.layer.shadowOpacity = 0.1
        
        return button
    }()
    
    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(LanguageManager.shared.localizedString(for: "next_question"), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .primaryPurple
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 25
        button.isHidden = true
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Gölge efekti
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 8
        button.layer.shadowOpacity = 0.1
        
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
        
        // Ana container view
        let topContainer = UIView()
        topContainer.translatesAutoresizingMaskIntoConstraints = false
        topContainer.backgroundColor = .clear
        
        // Geri butonu tasarımı
        let backButton = UIButton(type: .system)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Icon ayarları
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        let image = UIImage(systemName: "chevron.left", withConfiguration: config)
        backButton.setImage(image, for: .normal)
        
        // Görünüm ayarları
        backButton.backgroundColor = .primaryPurple
        backButton.tintColor = .white
        backButton.layer.cornerRadius = 18
        
        // Progress container
        let progressContainer = UIView()
        progressContainer.translatesAutoresizingMaskIntoConstraints = false
        progressContainer.backgroundColor = .clear
        
        // Stack view ayarları
        optionsStackView.axis = .vertical
        optionsStackView.spacing = 16
        optionsStackView.distribution = .fill
        
        view.addSubview(topContainer)
        topContainer.addSubview(backButton)
        topContainer.addSubview(progressContainer)
        progressContainer.addSubview(progressView)
        progressContainer.addSubview(progressLabel)
        view.addSubview(timerContainer)
        timerContainer.addSubview(timerLabel)
        view.addSubview(questionContainer)
        questionContainer.addSubview(questionLabel)
        view.addSubview(optionsStackView)
        view.addSubview(askGPTButton)
        view.addSubview(nextButton)
        
        setupTimerUI()
        
        NSLayoutConstraint.activate([
            // Top container constraints
            topContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            topContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            topContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            topContainer.heightAnchor.constraint(equalToConstant: 36),
            
            // Geri butonu constraints
            backButton.leadingAnchor.constraint(equalTo: topContainer.leadingAnchor),
            backButton.centerYAnchor.constraint(equalTo: topContainer.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 36),
            backButton.heightAnchor.constraint(equalToConstant: 36),
            
            // Progress container constraints
            progressContainer.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 16),
            progressContainer.trailingAnchor.constraint(equalTo: topContainer.trailingAnchor),
            progressContainer.centerYAnchor.constraint(equalTo: topContainer.centerYAnchor),
            progressContainer.heightAnchor.constraint(equalToConstant: 8),
            
            // Progress view constraints
            progressView.leadingAnchor.constraint(equalTo: progressContainer.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: progressLabel.leadingAnchor, constant: -8),
            progressView.centerYAnchor.constraint(equalTo: progressContainer.centerYAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 8),
            
            // Progress label constraints
            progressLabel.centerYAnchor.constraint(equalTo: progressContainer.centerYAnchor),
            progressLabel.trailingAnchor.constraint(equalTo: progressContainer.trailingAnchor),
            progressLabel.widthAnchor.constraint(equalToConstant: 50),
            
            // Timer container constraints
            timerContainer.topAnchor.constraint(equalTo: topContainer.bottomAnchor, constant: 24),
            timerContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            timerContainer.widthAnchor.constraint(equalToConstant: 60),
            timerContainer.heightAnchor.constraint(equalToConstant: 60),
            
            timerLabel.centerXAnchor.constraint(equalTo: timerContainer.centerXAnchor),
            timerLabel.centerYAnchor.constraint(equalTo: timerContainer.centerYAnchor),
            
            // Question container constraints
            questionContainer.topAnchor.constraint(equalTo: timerContainer.bottomAnchor, constant: 24),
            questionContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            questionContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            questionLabel.topAnchor.constraint(equalTo: questionContainer.topAnchor, constant: 24),
            questionLabel.leadingAnchor.constraint(equalTo: questionContainer.leadingAnchor, constant: 24),
            questionLabel.trailingAnchor.constraint(equalTo: questionContainer.trailingAnchor, constant: -24),
            questionLabel.bottomAnchor.constraint(equalTo: questionContainer.bottomAnchor, constant: -24),
            
            // Options stack view constraints
            optionsStackView.topAnchor.constraint(equalTo: questionContainer.bottomAnchor, constant: 32),
            optionsStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            optionsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            optionsStackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            
            askGPTButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            askGPTButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            askGPTButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5, constant: -40),
            askGPTButton.heightAnchor.constraint(equalToConstant: 50),
            
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            nextButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.3, constant: 20),
            nextButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        backButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
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
    
    private func createOptionButton(with title: String, tag: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18)
        button.setTitleColor(.darkGray, for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 15
        button.tag = tag
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        button.addTarget(self, action: #selector(optionButtonTapped(_:)), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Gölge efekti
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 8
        button.layer.shadowOpacity = 0.1
        
        // Çerçeve
        button.layer.borderWidth = 1.5
        button.layer.borderColor = UIColor.systemGray4.cgColor
        
        // Minimum yükseklik constraint'i
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 56).isActive = true
        
        return button
    }
    
    private func updateUI(with question: Question?) {
        guard let question = question else { return }
        
        // Clear existing option buttons
        optionsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Update progress
        let progress = Float(viewModel.currentQuestionIndex) / Float(viewModel.totalQuestions)
        progressView.setProgress(progress, animated: true)
        progressLabel.text = "\(viewModel.currentQuestionIndex + 1)/\(viewModel.totalQuestions)"
        
        // Update question text with animation
        UIView.transition(with: questionLabel, duration: 0.3, options: .transitionCrossDissolve) {
            self.questionLabel.text = question.text
        }
        
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
            
            // Add options to grid with animation
            for (index, option) in question.options.enumerated() {
                let containerView = UIView()
                containerView.backgroundColor = .white
                containerView.layer.cornerRadius = 15
                containerView.layer.borderWidth = 1
                containerView.layer.borderColor = UIColor.systemGray4.cgColor
                containerView.layer.shadowColor = UIColor.black.cgColor
                containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
                containerView.layer.shadowRadius = 6
                containerView.layer.shadowOpacity = 0.1
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
                button.setTitle("", for: .normal)
                button.tag = index
                button.addTarget(self, action: #selector(optionButtonTapped(_:)), for: .touchUpInside)
                button.translatesAutoresizingMaskIntoConstraints = false
                
                containerView.addSubview(imageView)
                containerView.addSubview(button)
                
                NSLayoutConstraint.activate([
                    imageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
                    imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
                    imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
                    imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
                    
                    button.topAnchor.constraint(equalTo: containerView.topAnchor),
                    button.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                    button.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                    button.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
                ])
                
                // Add to appropriate row with animation
                UIView.animate(withDuration: 0.3, delay: Double(index) * 0.1) {
                    if index < 2 {
                        topRow.addArrangedSubview(containerView)
                    } else {
                        bottomRow.addArrangedSubview(containerView)
                    }
                    containerView.alpha = 1
                }
            }
        } else {
            // Add text options with animation
            for (index, option) in question.options.enumerated() {
                let button = createOptionButton(with: option, tag: index)
                button.alpha = 0
                optionsStackView.addArrangedSubview(button)
                
                UIView.animate(withDuration: 0.3, delay: Double(index) * 0.1) {
                    button.alpha = 1
                    button.transform = .identity
                }
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
        timer?.invalidate()
        viewModel.answerQuestion(nil)
        
        // Show Ask GPT and Next buttons when time runs out
        UIView.animate(withDuration: 0.3) {
            self.askGPTButton.isHidden = false
            self.nextButton.isHidden = false
            self.askGPTButton.alpha = 1
            self.nextButton.alpha = 1
        }
        
        // Highlight correct answer in green with animation
        guard let currentQuestion = viewModel.currentQuestion else { return }
        
        if let optionImages = currentQuestion.optionImages, !optionImages.isEmpty {
            if let gridContainer = optionsStackView.arrangedSubviews.first as? UIStackView {
                var allOptionViews: [UIView] = []
                
                for rowStack in gridContainer.arrangedSubviews {
                    guard let row = rowStack as? UIStackView else { continue }
                    allOptionViews.append(contentsOf: row.arrangedSubviews)
                }
                
                let correctIndex = currentQuestion.options.firstIndex(of: currentQuestion.correctAnswer) ?? -1
                
                UIView.animate(withDuration: 0.3) {
                    for (index, optionContainer) in allOptionViews.enumerated() {
                        if index == correctIndex {
                            optionContainer.layer.borderWidth = 3
                            optionContainer.layer.borderColor = UIColor.systemGreen.cgColor
                            optionContainer.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                        } else {
                            optionContainer.alpha = 0.5
                        }
                        
                        if let button = optionContainer.subviews.last as? UIButton {
                            button.isEnabled = false
                        }
                    }
                }
            }
        } else {
            UIView.animate(withDuration: 0.3) {
                self.optionsStackView.arrangedSubviews.forEach { view in
                    guard let button = view as? UIButton,
                          let title = button.title(for: .normal) else { return }
                    
                    if title == currentQuestion.correctAnswer {
                        button.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.2)
                        button.layer.borderColor = UIColor.systemGreen.cgColor
                        button.setTitleColor(.systemGreen, for: .normal)
                        button.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                    } else {
                        button.alpha = 0.5
                    }
                    button.isEnabled = false
                }
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
        
        // Highlight correct and wrong answers with animation
        if let optionImages = currentQuestion.optionImages, !optionImages.isEmpty {
            if let gridContainer = optionsStackView.arrangedSubviews.first as? UIStackView {
                var allOptionViews: [UIView] = []
                
                for rowStack in gridContainer.arrangedSubviews {
                    guard let row = rowStack as? UIStackView else { continue }
                    allOptionViews.append(contentsOf: row.arrangedSubviews)
                }
                
                let correctIndex = currentQuestion.options.firstIndex(of: currentQuestion.correctAnswer) ?? -1
                
                UIView.animate(withDuration: 0.3) {
                    for (index, optionContainer) in allOptionViews.enumerated() {
                        if index == correctIndex {
                            optionContainer.layer.borderWidth = 3
                            optionContainer.layer.borderColor = UIColor.systemGreen.cgColor
                            optionContainer.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                        } else if index == selectedIndex && index != correctIndex {
                            optionContainer.layer.borderWidth = 3
                            optionContainer.layer.borderColor = UIColor.systemRed.cgColor
                            optionContainer.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                        }
                        
                        if let button = optionContainer.subviews.last as? UIButton {
                            button.isEnabled = false
                        }
                    }
                }
            }
        } else {
            UIView.animate(withDuration: 0.3) {
                self.optionsStackView.arrangedSubviews.forEach { view in
                    guard let button = view as? UIButton,
                          let title = button.title(for: .normal) else { return }
                    
                    if title == currentQuestion.correctAnswer {
                        button.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.2)
                        button.layer.borderColor = UIColor.systemGreen.cgColor
                        button.setTitleColor(.systemGreen, for: .normal)
                        button.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                    } else if title == selectedAnswer && title != currentQuestion.correctAnswer {
                        button.backgroundColor = UIColor.systemRed.withAlphaComponent(0.2)
                        button.layer.borderColor = UIColor.systemRed.cgColor
                        button.setTitleColor(.systemRed, for: .normal)
                        button.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                    }
                    button.isEnabled = false
                }
            }
        }
        
        // Doğru cevap kontrolü ve geçiş
        let isCorrect = selectedAnswer == currentQuestion.correctAnswer
        
        if isCorrect {
            // Doğru cevap verildiğinde 1 saniye bekleyip diğer soruya geç
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.viewModel.nextQuestion()
            }
        } else {
            // Yanlış cevap verildiğinde Ask GPT ve Next butonlarını göster
            UIView.animate(withDuration: 0.3) {
                self.askGPTButton.isHidden = false
                self.nextButton.isHidden = false
                self.askGPTButton.alpha = 1
                self.nextButton.alpha = 1
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
