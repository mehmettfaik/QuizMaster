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
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
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
        view.addSubview(questionLabel)
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            timerLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 20),
            timerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            questionLabel.topAnchor.constraint(equalTo: timerLabel.bottomAnchor, constant: 40),
            questionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            questionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            stackView.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: 40),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
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
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Update question
        questionLabel.text = question.text
        
        // Update progress
        let progress = Float(viewModel.currentQuestionIndex) / Float(viewModel.totalQuestions)
        progressView.setProgress(progress, animated: true)
        
        // Create option buttons
        question.options.forEach { option in
            let button = UIButton(type: .system)
            button.setTitle(option, for: .normal)
            button.backgroundColor = .backgroundPurple
            button.setTitleColor(.black, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 16)
            button.layer.cornerRadius = 8
            button.heightAnchor.constraint(equalToConstant: 50).isActive = true
            button.addTarget(self, action: #selector(optionButtonTapped(_:)), for: .touchUpInside)
            stackView.addArrangedSubview(button)
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
        stackView.arrangedSubviews.forEach { view in
            guard let button = view as? UIButton,
                  let title = button.title(for: .normal) else { return }
            
            if title == viewModel.currentQuestion?.correctAnswer {
                button.backgroundColor = .systemGreen
                button.setTitleColor(.white, for: .normal)
            } else if title == answer && title != viewModel.currentQuestion?.correctAnswer {
                button.backgroundColor = .systemRed
                button.setTitleColor(.white, for: .normal)
            }
            button.isEnabled = false
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