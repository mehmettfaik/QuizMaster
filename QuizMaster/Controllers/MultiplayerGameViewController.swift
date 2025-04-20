import UIKit
import FirebaseAuth
import FirebaseFirestore

// Add CircularTimerView class before MultiplayerGameViewController
class CircularTimerView: UIView {
    private let progressLayer = CAShapeLayer()
    private let backgroundLayer = CAShapeLayer()
    private let timeLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        // Background circle
        let backgroundPath = UIBezierPath(arcCenter: CGPoint(x: bounds.midX, y: bounds.midY),
                                        radius: bounds.width/2 - 10,
                                        startAngle: -(.pi/2),
                                        endAngle: 2 * .pi - .pi/2,
                                        clockwise: true)
        
        backgroundLayer.path = backgroundPath.cgPath
        backgroundLayer.fillColor = UIColor.clear.cgColor
        backgroundLayer.strokeColor = UIColor.systemGray5.cgColor
        backgroundLayer.lineWidth = 8
        backgroundLayer.lineCap = .round
        layer.addSublayer(backgroundLayer)
        
        // Progress circle
        progressLayer.path = backgroundPath.cgPath
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = UIColor.primaryPurple.cgColor
        progressLayer.lineWidth = 8
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 1
        layer.addSublayer(progressLayer)
        
        // Time label
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.textAlignment = .center
        timeLabel.font = .systemFont(ofSize: 32, weight: .bold)
        timeLabel.textColor = .primaryPurple
        addSubview(timeLabel)
        
        NSLayoutConstraint.activate([
            timeLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            timeLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let backgroundPath = UIBezierPath(arcCenter: CGPoint(x: bounds.midX, y: bounds.midY),
                                        radius: bounds.width/2 - 10,
                                        startAngle: -(.pi/2),
                                        endAngle: 2 * .pi - .pi/2,
                                        clockwise: true)
        
        backgroundLayer.path = backgroundPath.cgPath
        progressLayer.path = backgroundPath.cgPath
    }
    
    func updateTime(timeLeft: Int, totalTime: Int) {
        timeLabel.text = "\(timeLeft)"
        
        let progress = CGFloat(timeLeft) / CGFloat(totalTime)
        progressLayer.strokeEnd = progress
        
        // Update colors based on time left using purple shades
        let color = progress > 0.5 ? UIColor.primaryPurple : (progress > 0.2 ? UIColor.systemPurple : UIColor.systemPurple.withAlphaComponent(0.6))
        progressLayer.strokeColor = color.cgColor
        timeLabel.textColor = color
    }
}

class MultiplayerGameViewController: UIViewController {
    private var game: MultiplayerGame
    private let multiplayerService = MultiplayerGameService.shared
    private var gameListener: ListenerRegistration?
    private var answerListener: ListenerRegistration?
    
    private var bothPlayersAnswered = false
    private var showingCorrectAnswer = false
    private var nextQuestionTimer: Timer?
    private var waitingForNextQuestion = false
    private var hasAnsweredCurrentQuestion = false
    
    private var selectedButton: UIButton?
    
    private let circularTimerView: CircularTimerView = {
        let view = CircularTimerView(frame: CGRect(x: 0, y: 0, width: 120, height: 120))
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let questionContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 20
        view.layer.shadowColor = UIColor.primaryPurple.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 12
        view.layer.shadowOpacity = 0.2
        return view
    }()
    
    private let questionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .primaryPurple
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        return label
    }()
    
    private let scoreView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.systemGray4.cgColor
        
        // Add shadow
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.1
        return view
    }()
    
    private let yourScoreLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .label
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        return label
    }()
    
    private let opponentScoreLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        return label
    }()
    
    private let vsLabel: UILabel = {
        let label = UILabel()
        label.text = "VS"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16, weight: .black)
        label.textColor = .primaryPurple
        return label
    }()
    
    private let scoreStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 20
        return stack
    }()
    
    private let answerStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.distribution = .fillEqually
        stack.spacing = 12
        return stack
    }()
    
    private var timer: Timer?
    private var timeLeft: Int = 5 // 5 seconds per question
    private var currentQuestion: Question?
    
    init(game: MultiplayerGame) {
        self.game = game
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGameListener()
        loadQuestion(at: game.currentQuestionIndex)
        
        // Navigation bar düzenlemeleri
        title = "Multiplayer Quiz"
        navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.primaryPurple,
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18, weight: .bold)
        ]
        
        // Geri butonu düzenlemeleri
        let backButton = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(backButtonTapped))
        backButton.tintColor = .primaryPurple
        navigationItem.leftBarButtonItem = backButton
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        gameListener?.remove()
        answerListener?.remove()
        timer?.invalidate()
        nextQuestionTimer?.invalidate()
    }
    
    private func setupUI() {
        title = "Multiplayer Quiz"
        view.backgroundColor = UIColor.primaryPurple.withAlphaComponent(0.1)
        
        // Add subviews
        [circularTimerView, scoreView, questionContainerView, answerStackView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        questionContainerView.addSubview(questionLabel)
        questionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Score view setup
        scoreView.addSubview(scoreStackView)
        scoreStackView.addArrangedSubview(yourScoreLabel)
        scoreStackView.addArrangedSubview(vsLabel)
        scoreStackView.addArrangedSubview(opponentScoreLabel)
        scoreStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            circularTimerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            circularTimerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            circularTimerView.widthAnchor.constraint(equalToConstant: 120),
            circularTimerView.heightAnchor.constraint(equalToConstant: 120),
            
            scoreView.topAnchor.constraint(equalTo: circularTimerView.bottomAnchor, constant: 20),
            scoreView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            scoreView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            scoreView.heightAnchor.constraint(equalToConstant: 100),
            
            scoreStackView.leadingAnchor.constraint(equalTo: scoreView.leadingAnchor, constant: 16),
            scoreStackView.trailingAnchor.constraint(equalTo: scoreView.trailingAnchor, constant: -16),
            scoreStackView.topAnchor.constraint(equalTo: scoreView.topAnchor, constant: 16),
            scoreStackView.bottomAnchor.constraint(equalTo: scoreView.bottomAnchor, constant: -16),
            
            questionContainerView.topAnchor.constraint(equalTo: scoreView.bottomAnchor, constant: 24),
            questionContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            questionContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            questionContainerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120), // Minimum height
            
            questionLabel.topAnchor.constraint(equalTo: questionContainerView.topAnchor, constant: 24),
            questionLabel.leadingAnchor.constraint(equalTo: questionContainerView.leadingAnchor, constant: 24),
            questionLabel.trailingAnchor.constraint(equalTo: questionContainerView.trailingAnchor, constant: -24),
            questionLabel.bottomAnchor.constraint(equalTo: questionContainerView.bottomAnchor, constant: -24),
            
            answerStackView.topAnchor.constraint(equalTo: questionContainerView.bottomAnchor, constant: 32),
            answerStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            answerStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            answerStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        ])
        
        updateScoreLabel()
    }
    
    private func setupGameListener() {
        gameListener = multiplayerService.listenForGameUpdates(gameId: game.id) { [weak self] result in
            switch result {
            case .success(let updatedGame):
                self?.handleGameUpdate(updatedGame)
            case .failure(let error):
                print("Error listening for game updates: \(error.localizedDescription)")
            }
        }
    }
    
    private func handleGameUpdate(_ updatedGame: MultiplayerGame) {
        // Oyun verilerini güncelle
        if let currentUserId = Auth.auth().currentUser?.uid {
            let currentPlayerScore = updatedGame.playerScores[currentUserId]?.score ?? 0
            let opponentId = updatedGame.creatorId == currentUserId ? updatedGame.invitedId : updatedGame.creatorId
            let opponentScore = updatedGame.playerScores[opponentId]?.score ?? 0
            
            DispatchQueue.main.async {
                self.updateScoreLabel(with: updatedGame)
            }
        }
        
        // Oyun tamamlandıysa sonuç ekranını göster
        if updatedGame.status == .completed {
            endGame()
            return
        }
        
        // Soru değiştiyse yeni soruyu yükle
        if updatedGame.currentQuestionIndex != game.currentQuestionIndex {
            // Timer'ları temizle
            timer?.invalidate()
            nextQuestionTimer?.invalidate()
            
            // Game referansını güncelle
            self.game = updatedGame
            
            // Yeni soruyu yükle
            loadQuestion(at: updatedGame.currentQuestionIndex)
            
            // Bekleme durumunu sıfırla
            waitingForNextQuestion = false
        }
    }
    
    private func updateScoreLabel(with updatedGame: MultiplayerGame? = nil) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let gameToUse = updatedGame ?? game
        
        // Mevcut oyuncunun bilgileri
        let currentPlayerScore = gameToUse.playerScores[currentUserId]?.score ?? 0
        let currentPlayerCorrect = gameToUse.playerScores[currentUserId]?.correctAnswers ?? 0
        
        // Rakip oyuncunun bilgileri
        let opponentId = gameToUse.creatorId == currentUserId ? gameToUse.invitedId : gameToUse.creatorId
        let opponentScore = gameToUse.playerScores[opponentId]?.score ?? 0
        let opponentCorrect = gameToUse.playerScores[opponentId]?.correctAnswers ?? 0
        
        // Kullanıcı isimlerini belirle
        let currentPlayerName = currentUserId == gameToUse.creatorId ? gameToUse.creatorName : gameToUse.invitedName
        let opponentName = currentUserId == gameToUse.creatorId ? gameToUse.invitedName : gameToUse.creatorName
        
        // Skor etiketlerini güncelle
        DispatchQueue.main.async {
            // Mevcut oyuncunun skoru
            let currentPlayerText = """
                \(currentPlayerName)
                \(currentPlayerScore) pts
                """
            self.yourScoreLabel.text = currentPlayerText
            self.yourScoreLabel.textColor = .label
            
            // Rakibin skoru
            let opponentText = """
                \(opponentName)
                \(opponentScore) pts
                """
            self.opponentScoreLabel.text = opponentText
            self.opponentScoreLabel.textColor = .secondaryLabel
        }
    }
    
    private func loadQuestion(at index: Int) {
        guard let questions = game.questions, index < questions.count else {
            endGame()
            return
        }
        
        let questionId = questions[index]
        multiplayerService.getQuestion(questionId: questionId) { [weak self] result in
            switch result {
            case .success(let question):
                self?.displayQuestion(question)
            case .failure(let error):
                print("Error loading question: \(error.localizedDescription)")
            }
        }
    }
    
    private func displayQuestion(_ question: Question) {
        currentQuestion = question
        bothPlayersAnswered = false
        showingCorrectAnswer = false
        waitingForNextQuestion = false
        selectedButton = nil
        hasAnsweredCurrentQuestion = false
        
        DispatchQueue.main.async {
            self.questionLabel.text = question.text
            self.answerStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
            
            for option in question.options {
                let button = UIButton(type: .system)
                button.setTitle(option, for: .normal)
                button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
                button.titleLabel?.numberOfLines = 2
                button.titleLabel?.adjustsFontSizeToFitWidth = true
                button.titleLabel?.minimumScaleFactor = 0.8
                button.backgroundColor = .systemBackground
                button.setTitleColor(.primaryPurple, for: .normal)
                button.layer.cornerRadius = 16
                button.layer.borderWidth = 2
                button.layer.borderColor = UIColor.primaryPurple.cgColor
                
                // Add shadow
                button.layer.shadowColor = UIColor.primaryPurple.cgColor
                button.layer.shadowOffset = CGSize(width: 0, height: 2)
                button.layer.shadowRadius = 6
                button.layer.shadowOpacity = 0.2
                
                button.heightAnchor.constraint(equalToConstant: 60).isActive = true
                button.addTarget(self, action: #selector(self.answerButtonTapped(_:)), for: .touchUpInside)
                self.answerStackView.addArrangedSubview(button)
            }
            
            self.answerStackView.spacing = 16
            self.startTimer()
            self.setupAnswerListener()
        }
    }
    
    private func setupAnswerListener() {
        answerListener?.remove()
        answerListener = multiplayerService.listenForAnswers(gameId: game.id) { [weak self] result in
            switch result {
            case .success(let answers):
                self?.checkIfBothPlayersAnswered(answers)
            case .failure(let error):
                print("Error listening for answers: \(error.localizedDescription)")
            }
        }
    }
    
    private func checkIfBothPlayersAnswered(_ answers: [String: Bool]) {
        guard !bothPlayersAnswered,
              !showingCorrectAnswer else { return }
        
        if answers.count == 2 {
            bothPlayersAnswered = true
            DispatchQueue.main.async { [weak self] in
                self?.showCorrectAnswer()
            }
        }
    }
    
    private func showCorrectAnswer() {
        guard let currentQuestion = currentQuestion,
              !showingCorrectAnswer else { return }
        
        showingCorrectAnswer = true
        
        // Timer'ı durdur
        timer?.invalidate()
        
        answerStackView.arrangedSubviews.forEach { view in
            guard let button = view as? UIButton,
                  let buttonTitle = button.title(for: .normal) else { return }
            
            if buttonTitle == currentQuestion.correctAnswer {
                button.backgroundColor = .systemGreen
            } else {
                if button == selectedButton {
                    button.backgroundColor = .systemRed
                } else {
                    button.backgroundColor = .systemGray
                }
            }
        }
        
        // 2 saniye sonra bir sonraki soruya geç
        nextQuestionTimer?.invalidate()
        nextQuestionTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            // Eğer oyunu oluşturan kullanıcı isek ve henüz bekleme durumunda değilsek
            if self.game.creatorId == Auth.auth().currentUser?.uid && !self.waitingForNextQuestion {
                self.moveToNextQuestion()
            }
        }
    }
    
    private func moveToNextQuestion() {
        guard !waitingForNextQuestion else { return }
        waitingForNextQuestion = true
        
        // Eğer son soru ise oyunu bitir
        if let questions = game.questions,
           game.currentQuestionIndex >= questions.count - 1 {
            multiplayerService.updateGameStatus(gameId: game.id, status: .completed) { [weak self] result in
                switch result {
                case .success:
                    print("✅ Game completed successfully")
                case .failure(let error):
                    print("❌ Error completing game: \(error.localizedDescription)")
                    self?.waitingForNextQuestion = false
                }
            }
        } else {
            // Sonraki soruya geç
            multiplayerService.moveToNextQuestion(gameId: game.id) { [weak self] result in
                switch result {
                case .success:
                    print("✅ Moved to next question successfully")
                case .failure(let error):
                    print("❌ Error moving to next question: \(error.localizedDescription)")
                    self?.waitingForNextQuestion = false
                }
            }
        }
    }
    
    private func startTimer() {
        timeLeft = 5
        updateTimerLabel()
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            self.timeLeft -= 1
            self.updateTimerLabel()
            
            if self.timeLeft <= 0 {
                self.timer?.invalidate()
                self.handleTimeUp()
            }
        }
    }
    
    private func updateTimerLabel() {
        circularTimerView.updateTime(timeLeft: timeLeft, totalTime: 5)
    }
    
    private func animateScoreChange(for label: UILabel, from oldScore: Int, to newScore: Int) {
        // Skor değişim animasyonu
        let duration: TimeInterval = 1.0
        let steps = 10
        let stepDuration = duration / TimeInterval(steps)
        let scoreDifference = newScore - oldScore
        let stepValue = Double(scoreDifference) / Double(steps)
        
        // Label'ı büyüt
        UIView.animate(withDuration: 0.2, animations: {
            label.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            label.textColor = .systemGreen
        })
        
        // Skor artış animasyonu
        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                let currentValue = oldScore + Int(Double(i) * stepValue)
                let text = label.text?.components(separatedBy: "\n").first ?? ""
                label.text = "\(text)\n\(currentValue)"
                
                // Son adımda label'ı normal boyutuna döndür
                if i == steps {
                    UIView.animate(withDuration: 0.2, animations: {
                        label.transform = .identity
                        label.textColor = .label
                    })
                }
            }
        }
    }
    
    private func highlightSelectedButton(_ button: UIButton) {
        // Reset previous button
        selectedButton?.backgroundColor = .systemBackground
        selectedButton?.setTitleColor(.primaryPurple, for: .normal)
        selectedButton?.transform = .identity
        
        // Highlight new button
        button.backgroundColor = .primaryPurple
        button.setTitleColor(.white, for: .normal)
        
        // Add animation
        UIView.animate(withDuration: 0.2) {
            button.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
        } completion: { _ in
            UIView.animate(withDuration: 0.1) {
                button.transform = .identity
            }
        }
        
        selectedButton = button
        
        // Disable ALL buttons including the selected one
        answerStackView.arrangedSubviews.forEach { view in
            if let button = view as? UIButton {
                button.isEnabled = false
                if button != selectedButton {
                    button.alpha = 0.5
                    button.backgroundColor = UIColor.primaryPurple.withAlphaComponent(0.1)
                }
            }
        }
    }
    
    @objc private func answerButtonTapped(_ button: UIButton) {
        guard let currentQuestion = currentQuestion,
              let answer = button.title(for: .normal),
              let currentUserId = Auth.auth().currentUser?.uid,
              !showingCorrectAnswer,
              !hasAnsweredCurrentQuestion else {
            return
        }
        
        hasAnsweredCurrentQuestion = true
        selectedButton = button
        
        button.backgroundColor = .systemCyan
        
        answerStackView.arrangedSubviews.forEach { view in
            guard let otherButton = view as? UIButton else { return }
            otherButton.isUserInteractionEnabled = false
            if otherButton != button {
                otherButton.alpha = 0.5
                otherButton.backgroundColor = .systemGray
            }
        }
        
        let isCorrect = answer == currentQuestion.correctAnswer
        
        multiplayerService.submitAnswer(gameId: game.id, userId: currentUserId, isCorrect: isCorrect) { [weak self] _ in
            if isCorrect {
                let oldScore = self?.game.playerScores[currentUserId]?.score ?? 0
                DispatchQueue.main.async {
                    self?.animateScoreChange(for: self?.yourScoreLabel ?? UILabel(), from: oldScore, to: oldScore + 10)
                }
            }
            
            // Her iki oyuncu da cevap verdiyse veya süre dolduysa doğru cevabı göster
            if self?.bothPlayersAnswered == true || self?.timeLeft == 0 {
                DispatchQueue.main.async {
                    self?.showCorrectAnswer()
                }
            }
        }
    }
    
    private func handleTimeUp() {
        guard !showingCorrectAnswer else { return }
        
        // Süre dolduğunda henüz cevap verilmediyse otomatik olarak yanlış cevap gönder
        if let currentUserId = Auth.auth().currentUser?.uid, !hasAnsweredCurrentQuestion {
            multiplayerService.submitAnswer(gameId: game.id, userId: currentUserId, isCorrect: false) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.showCorrectAnswer()
                }
            }
        } else {
            showCorrectAnswer()
        }
    }
    
    private func endGame() {
        // Timer'ları temizle
        timer?.invalidate()
        nextQuestionTimer?.invalidate()
        
        // Firestore'dan en güncel oyun verilerini al
        multiplayerService.getGame(gameId: game.id) { [weak self] result in
            switch result {
            case .success(let finalGame):
                DispatchQueue.main.async {
                    self?.showResultScreen(with: finalGame)
                }
            case .failure(let error):
                print("Error fetching final game data: \(error.localizedDescription)")
                // Hata durumunda mevcut game verisiyle devam et
                DispatchQueue.main.async {
                    guard let currentGame = self?.game else { return }
                    self?.showResultScreen(with: currentGame)
                }
            }
        }
    }
    
    private func showResultScreen(with finalGame: MultiplayerGame) {
        let resultVC = UIViewController()
        resultVC.modalPresentationStyle = .fullScreen
        
        // Gradient background
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.primaryPurple.cgColor,
            UIColor.systemPurple.cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.frame = view.bounds
        resultVC.view.layer.insertSublayer(gradientLayer, at: 0)
        
        // Container view for content
        let contentView = UIView()
        contentView.backgroundColor = .clear
        contentView.translatesAutoresizingMaskIntoConstraints = false
        resultVC.view.addSubview(contentView)
        
        // Trophy image for winner
        let trophyImageView = UIImageView()
        trophyImageView.contentMode = .scaleAspectFit
        trophyImageView.translatesAutoresizingMaskIntoConstraints = false
        trophyImageView.tintColor = .white
        if #available(iOS 13.0, *) {
            trophyImageView.image = UIImage(systemName: "trophy.fill")
        }
        contentView.addSubview(trophyImageView)
        
        // Title label with custom styling
        let titleLabel = UILabel()
        titleLabel.text = "Online Quiz Bitti"
        titleLabel.font = .systemFont(ofSize: 32, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // Result card container
        let resultContainer = UIView()
        resultContainer.backgroundColor = .systemBackground
        resultContainer.layer.cornerRadius = 24
        resultContainer.clipsToBounds = true
        resultContainer.layer.masksToBounds = false
        resultContainer.layer.shadowColor = UIColor.black.cgColor
        resultContainer.layer.shadowOffset = CGSize(width: 0, height: 4)
        resultContainer.layer.shadowRadius = 12
        resultContainer.layer.shadowOpacity = 0.3
        resultContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(resultContainer)
        
        // Result content
        let resultLabel = UILabel()
        resultLabel.attributedText = getFormattedGameResultMessage(from: finalGame)
        resultLabel.numberOfLines = 0
        resultLabel.translatesAutoresizingMaskIntoConstraints = false
        resultContainer.addSubview(resultLabel)
        
        // Modern profile button
        let profileButton = UIButton(type: .system)
        profileButton.setTitle("Profili Görüntüle", for: .normal)
        profileButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        profileButton.backgroundColor = .white
        profileButton.setTitleColor(.primaryPurple, for: .normal)
        profileButton.layer.cornerRadius = 25
        profileButton.clipsToBounds = true
        profileButton.layer.masksToBounds = false
        profileButton.layer.shadowColor = UIColor.black.cgColor
        profileButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        profileButton.layer.shadowRadius = 8
        profileButton.layer.shadowOpacity = 0.2
        profileButton.translatesAutoresizingMaskIntoConstraints = false
        profileButton.addTarget(self, action: #selector(self.goToProfile), for: .touchUpInside)
        contentView.addSubview(profileButton)
        
        // Constraints
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: resultVC.view.safeAreaLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: resultVC.view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: resultVC.view.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: resultVC.view.safeAreaLayoutGuide.bottomAnchor),
            
            trophyImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            trophyImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            trophyImageView.heightAnchor.constraint(equalToConstant: 80),
            trophyImageView.widthAnchor.constraint(equalToConstant: 80),
            
            titleLabel.topAnchor.constraint(equalTo: trophyImageView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            resultContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            resultContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            resultContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            resultLabel.topAnchor.constraint(equalTo: resultContainer.topAnchor, constant: 24),
            resultLabel.leadingAnchor.constraint(equalTo: resultContainer.leadingAnchor, constant: 24),
            resultLabel.trailingAnchor.constraint(equalTo: resultContainer.trailingAnchor, constant: -24),
            resultLabel.bottomAnchor.constraint(equalTo: resultContainer.bottomAnchor, constant: -24),
            
            profileButton.topAnchor.constraint(equalTo: resultContainer.bottomAnchor, constant: 40),
            profileButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            profileButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            profileButton.heightAnchor.constraint(equalToConstant: 50),
            profileButton.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -20)
        ])
        
        // Add presentation animation
        resultVC.modalTransitionStyle = .crossDissolve
        present(resultVC, animated: true) {
            // Animate trophy image
            trophyImageView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            UIView.animate(withDuration: 0.6, delay: 0.1, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: [], animations: {
                trophyImageView.transform = .identity
            })
            
            // Animate result container
            resultContainer.transform = CGAffineTransform(translationX: 0, y: 50)
            resultContainer.alpha = 0
            UIView.animate(withDuration: 0.6, delay: 0.3, options: .curveEaseOut, animations: {
                resultContainer.transform = .identity
                resultContainer.alpha = 1
            })
            
            // Animate profile button
            profileButton.transform = CGAffineTransform(translationX: 0, y: 50)
            profileButton.alpha = 0
            UIView.animate(withDuration: 0.6, delay: 0.5, options: .curveEaseOut, animations: {
                profileButton.transform = .identity
                profileButton.alpha = 1
            })
        }
    }
    
    private func getFormattedGameResultMessage(from finalGame: MultiplayerGame) -> NSAttributedString {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return NSAttributedString() }
        
        let resultText = NSMutableAttributedString()
        
        // Style definitions
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 28, weight: .heavy),
            .foregroundColor: UIColor.primaryPurple
        ]
        
        let playerNameAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 22, weight: .bold),
            .foregroundColor: UIColor.label
        ]
        
        let statsLabelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 17, weight: .medium),
            .foregroundColor: UIColor.secondaryLabel
        ]
        
        let statsValueAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 20, weight: .bold),
            .foregroundColor: UIColor.primaryPurple
        ]
        
        // Current player info
        let currentPlayerName = currentUserId == finalGame.creatorId ? finalGame.creatorName : finalGame.invitedName
        let currentPlayerStats = finalGame.playerScores[currentUserId]
        let currentPlayerScore = currentPlayerStats?.score ?? 0
        let currentPlayerCorrect = currentPlayerStats?.correctAnswers ?? 0
        let currentPlayerWrong = currentPlayerStats?.wrongAnswers ?? 0
        
        // Opponent info
        let opponentId = finalGame.creatorId == currentUserId ? finalGame.invitedId : finalGame.creatorId
        let opponentName = currentUserId == finalGame.creatorId ? finalGame.invitedName : finalGame.creatorName
        let opponentStats = finalGame.playerScores[opponentId]
        let opponentScore = opponentStats?.score ?? 0
        let opponentCorrect = opponentStats?.correctAnswers ?? 0
        let opponentWrong = opponentStats?.wrongAnswers ?? 0
        
        // Determine winner/loser status and emoji
        let (resultStatus, emoji) = {
            if currentPlayerScore > opponentScore {
                return ("Tebrikler! Kazandınız!", "🏆")
            } else if currentPlayerScore < opponentScore {
                return ("Maalesef kaybettiniz.", "😔")
            } else {
                return ("Berabere kaldınız!", "🤝")
            }
        }()
        
        // Add result status with emoji
        resultText.append(NSAttributedString(string: emoji + " " + resultStatus + "\n\n", attributes: titleAttributes))
        
        // Add current player stats
        resultText.append(NSAttributedString(string: "👤 " + currentPlayerName.uppercased() + "\n", attributes: playerNameAttributes))
        resultText.append(NSAttributedString(string: "Puan: ", attributes: statsLabelAttributes))
        resultText.append(NSAttributedString(string: "\(currentPlayerScore) pts\n", attributes: statsValueAttributes))
        resultText.append(NSAttributedString(string: "Doğru: ", attributes: statsLabelAttributes))
        resultText.append(NSAttributedString(string: "\(currentPlayerCorrect)\n", attributes: statsValueAttributes))
        resultText.append(NSAttributedString(string: "Yanlış: ", attributes: statsLabelAttributes))
        resultText.append(NSAttributedString(string: "\(currentPlayerWrong)\n\n", attributes: statsValueAttributes))
        
        // Add opponent stats
        resultText.append(NSAttributedString(string: "👤 " + opponentName.uppercased() + "\n", attributes: playerNameAttributes))
        resultText.append(NSAttributedString(string: "Puan: ", attributes: statsLabelAttributes))
        resultText.append(NSAttributedString(string: "\(opponentScore) pts\n", attributes: statsValueAttributes))
        resultText.append(NSAttributedString(string: "Doğru: ", attributes: statsLabelAttributes))
        resultText.append(NSAttributedString(string: "\(opponentCorrect)\n", attributes: statsValueAttributes))
        resultText.append(NSAttributedString(string: "Yanlış: ", attributes: statsLabelAttributes))
        resultText.append(NSAttributedString(string: "\(opponentWrong)", attributes: statsValueAttributes))
        
        return resultText
    }
    
    @objc private func goToProfile() {
        // Profil sayfasına yönlendir
        dismiss(animated: true) { [weak self] in
            self?.navigationController?.popToRootViewController(animated: true)
        }
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
}

