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
        progress.translatesAutoresizingMaskIntoConstraints = false
        return progress
    }()
    
    private let timerLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .primaryPurple
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let questionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20)
        label.textColor = .black
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let questionImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = true
        return imageView
    }()
    
    private let optionsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
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
        
        view.addSubview(progressView)
        view.addSubview(timerLabel)
        view.addSubview(questionImageView)
        view.addSubview(questionLabel)
        view.addSubview(optionsStackView)
        
        // Constraint'leri oluştur
        questionLabelTopToImageConstraint = questionLabel.topAnchor.constraint(equalTo: questionImageView.bottomAnchor, constant: 20)
        questionLabelTopToTimerConstraint = questionLabel.topAnchor.constraint(equalTo: timerLabel.bottomAnchor, constant: 40)
        
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            timerLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 20),
            timerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            questionImageView.topAnchor.constraint(equalTo: timerLabel.bottomAnchor, constant: 20),
            questionImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            questionImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            questionImageView.heightAnchor.constraint(equalToConstant: 200),
            
            questionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            questionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            optionsStackView.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: 20),
            optionsStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            optionsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .primaryPurple
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44)
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
        
        // Update question text
        questionLabel.text = question.text
        
        // Update question image and layout
        if let imageName = question.questionImage {
            questionImageView.image = UIImage(named: imageName)
            questionImageView.isHidden = false
            questionLabelTopToTimerConstraint.isActive = false
            questionLabelTopToImageConstraint.isActive = true
        } else {
            questionImageView.isHidden = true
            questionLabelTopToImageConstraint.isActive = false
            questionLabelTopToTimerConstraint.isActive = true
        }
        
        // Update progress
        let progress = Float(viewModel.currentQuestionIndex) / Float(viewModel.totalQuestions)
        progressView.setProgress(progress, animated: true)
        
        // Check if options have images
        if let optionImages = question.optionImages, !optionImages.isEmpty {
            // Create 2x2 grid layout for image options
            let gridContainer = UIStackView()
            gridContainer.axis = .vertical
            gridContainer.spacing = 16
            gridContainer.distribution = .fillEqually
            gridContainer.translatesAutoresizingMaskIntoConstraints = false
            
            // Create two horizontal stack views for rows
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
                containerView.backgroundColor = .clear // Container'ı şeffaf yap
                containerView.layer.cornerRadius = 12
                containerView.translatesAutoresizingMaskIntoConstraints = false
                
                // Add image
                let imageView = UIImageView()
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                imageView.layer.cornerRadius = 12 // Container ile aynı corner radius
                imageView.translatesAutoresizingMaskIntoConstraints = false
                if index < optionImages.count {
                    imageView.image = UIImage(named: optionImages[index])
                }
                
                containerView.addSubview(imageView)
                
                // Add tap gesture
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(optionViewTapped(_:)))
                containerView.addGestureRecognizer(tapGesture)
                containerView.isUserInteractionEnabled = true
                
                // Store the option text for later use
                containerView.accessibilityLabel = option
                
                NSLayoutConstraint.activate([
                    imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
                    imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                    imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                    imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
                ])
                
                // Add to appropriate row
                if index < 2 {
                    topRow.addArrangedSubview(containerView)
                } else {
                    bottomRow.addArrangedSubview(containerView)
                }
            }
            
            // Set grid container height
            gridContainer.heightAnchor.constraint(equalToConstant: 280).isActive = true
            
        } else {
            // Create regular vertical list for non-image options
            for option in question.options {
                let containerView = UIView()
                containerView.backgroundColor = .backgroundPurple
                containerView.layer.cornerRadius = 12
                containerView.translatesAutoresizingMaskIntoConstraints = false
                
                let button = UIButton(type: .system)
                button.setTitle(option, for: .normal)
                button.setTitleColor(.black, for: .normal)
                button.titleLabel?.font = .systemFont(ofSize: 16)
                button.titleLabel?.numberOfLines = 0
                button.contentHorizontalAlignment = .center
                button.addTarget(self, action: #selector(optionButtonTapped(_:)), for: .touchUpInside)
                button.translatesAutoresizingMaskIntoConstraints = false
                
                containerView.addSubview(button)
                
                NSLayoutConstraint.activate([
                    button.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
                    button.topAnchor.constraint(equalTo: containerView.topAnchor),
                    button.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
                    button.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
                ])
                
                containerView.heightAnchor.constraint(equalToConstant: 50).isActive = true
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
        guard let answer = sender.title(for: .normal) else { return }
        
        timer?.invalidate()
        viewModel.answerQuestion(answer)
        
        // Highlight correct and wrong answers
        optionsStackView.arrangedSubviews.forEach { view in
            guard let containerView = view as? UIView,
                  let button = containerView.subviews.first(where: { $0 is UIButton }) as? UIButton,
                  let title = button.title(for: .normal) else { return }
            
            if title == viewModel.currentQuestion?.correctAnswer {
                containerView.backgroundColor = .systemGreen.withAlphaComponent(0.3)
                button.setTitleColor(.systemGreen, for: .normal)
            } else if title == answer && title != viewModel.currentQuestion?.correctAnswer {
                containerView.backgroundColor = .systemRed.withAlphaComponent(0.3)
                button.setTitleColor(.systemRed, for: .normal)
            }
            button.isEnabled = false
        }
        
        // Wait for a moment before moving to the next question
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.viewModel.nextQuestion()
        }
    }
    
    @objc private func optionViewTapped(_ gesture: UITapGestureRecognizer) {
        guard let containerView = gesture.view,
              let answer = containerView.accessibilityLabel else { return }
        
        timer?.invalidate()
        viewModel.answerQuestion(answer)
        
        // Highlight correct and wrong answers
        if let gridContainer = optionsStackView.arrangedSubviews.first as? UIStackView {
            for rowStack in gridContainer.arrangedSubviews {
                guard let row = rowStack as? UIStackView else { continue }
                
                for optionContainer in row.arrangedSubviews {
                    guard let option = optionContainer.accessibilityLabel else { continue }
                    
                    if option == viewModel.currentQuestion?.correctAnswer {
                        if let imageView = optionContainer.subviews.first as? UIImageView {
                            imageView.layer.borderWidth = 3
                            imageView.layer.borderColor = UIColor.systemGreen.cgColor
                        }
                    } else if option == answer && option != viewModel.currentQuestion?.correctAnswer {
                        if let imageView = optionContainer.subviews.first as? UIImageView {
                            imageView.layer.borderWidth = 3
                            imageView.layer.borderColor = UIColor.systemRed.cgColor
                        }
                    }
                    optionContainer.isUserInteractionEnabled = false
                }
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