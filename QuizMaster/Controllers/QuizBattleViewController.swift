import UIKit
import FirebaseFirestore
import Combine

class QuizBattleViewController: UIViewController {
    private let battleId: String
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    private var currentQuestion: [String: Any]?
    private var questions: [[String: Any]] = []
    private var currentQuestionIndex = 0
    private var timer: Timer?
    private var remainingTime: Int = 15
    private var userAnswers: [String: Int] = [:]
    private var players: [[String: Any]] = []
    
    // MARK: - UI Components
    private let containerStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let playersCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 16
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    private let questionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .label
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    private let timerLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 36, weight: .bold)
        label.textColor = .primaryPurple
        label.textAlignment = .center
        return label
    }()
    
    private let answersStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.distribution = .fillEqually
        return stack
    }()
    
    // MARK: - Initialization
    init(battleId: String) {
        self.battleId = battleId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
        loadQuestions()
        observePlayers()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Canlı Yarışma"
        
        view.addSubview(containerStackView)
        
        containerStackView.addArrangedSubview(playersCollectionView)
        containerStackView.addArrangedSubview(timerLabel)
        containerStackView.addArrangedSubview(questionLabel)
        containerStackView.addArrangedSubview(answersStackView)
        
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            containerStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            containerStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            containerStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            playersCollectionView.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    private func setupCollectionView() {
        playersCollectionView.delegate = self
        playersCollectionView.dataSource = self
        playersCollectionView.register(PlayerCell.self, forCellWithReuseIdentifier: "PlayerCell")
    }
    
    // MARK: - Game Logic
    private func loadQuestions() {
        // Firestore'dan soruları çek
        db.collection("questions")
            .limit(to: 10)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    self?.showErrorAlert(error)
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                self?.questions = documents.map { $0.data() }
                self?.startGame()
            }
    }
    
    private func startGame() {
        showNextQuestion()
    }
    
    private func showNextQuestion() {
        guard currentQuestionIndex < questions.count else {
            endGame()
            return
        }
        
        currentQuestion = questions[currentQuestionIndex]
        updateUI()
        startTimer()
    }
    
    private func updateUI() {
        guard let question = currentQuestion else { return }
        
        questionLabel.text = question["text"] as? String
        
        // Mevcut cevap butonlarını temizle
        answersStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Yeni cevap butonlarını ekle
        if let answers = question["answers"] as? [String] {
            for (index, answer) in answers.enumerated() {
                let button = createAnswerButton(answer, index: index)
                answersStackView.addArrangedSubview(button)
            }
        }
    }
    
    private func createAnswerButton(_ title: String, index: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .primaryPurple
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        button.tag = index
        button.addTarget(self, action: #selector(answerButtonTapped(_:)), for: .touchUpInside)
        return button
    }
    
    private func startTimer() {
        remainingTime = 15
        updateTimerLabel()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            
            self.remainingTime -= 1
            self.updateTimerLabel()
            
            if self.remainingTime <= 0 {
                timer.invalidate()
                self.timeUp()
            }
        }
    }
    
    private func updateTimerLabel() {
        timerLabel.text = "\(remainingTime)"
    }
    
    @objc private func answerButtonTapped(_ sender: UIButton) {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }
        
        // Cevabı kaydet
        userAnswers["\(currentQuestionIndex)"] = sender.tag
        
        // Firestore'a cevabı gönder
        db.collection("battles").document(battleId)
            .collection("answers").document(userId)
            .setData([
                "questionIndex": currentQuestionIndex,
                "answerIndex": sender.tag,
                "timeRemaining": remainingTime
            ], merge: true)
        
        // Sonraki soruya geç
        timer?.invalidate()
        currentQuestionIndex += 1
        showNextQuestion()
    }
    
    private func timeUp() {
        currentQuestionIndex += 1
        showNextQuestion()
    }
    
    private func endGame() {
        // Sonuçları hesapla ve göster
        calculateResults()
    }
    
    private func calculateResults() {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }
        
        var score = 0
        for (index, question) in questions.enumerated() {
            if let correctAnswer = question["correctAnswer"] as? Int,
               let userAnswer = userAnswers["\(index)"],
               correctAnswer == userAnswer {
                score += 1
            }
        }
        
        // Skoru Firestore'a kaydet
        db.collection("battles").document(battleId)
            .collection("scores").document(userId)
            .setData([
                "score": score,
                "timestamp": Timestamp(date: Date())
            ]) { [weak self] error in
                if let error = error {
                    self?.showErrorAlert(error)
                } else {
                    self?.showResults()
                }
            }
    }
    
    private func showResults() {
        let resultsVC = BattleResultsViewController(battleId: battleId)
        navigationController?.pushViewController(resultsVC, animated: true)
    }
    
    private func observePlayers() {
        db.collection("battles").document(battleId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let data = snapshot?.data(),
                      let playerIds = data["players"] as? [String] else { return }
                
                // Oyuncu bilgilerini çek
                self?.loadPlayerDetails(playerIds)
            }
    }
    
    private func loadPlayerDetails(_ playerIds: [String]) {
        let group = DispatchGroup()
        var tempPlayers: [[String: Any]] = []
        
        for playerId in playerIds {
            group.enter()
            db.collection("users").document(playerId).getDocument { snapshot, error in
                defer { group.leave() }
                
                if let data = snapshot?.data() {
                    tempPlayers.append(data)
                }
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.players = tempPlayers
            self?.playersCollectionView.reloadData()
        }
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension QuizBattleViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return players.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlayerCell", for: indexPath) as! PlayerCell
        let player = players[indexPath.item]
        cell.configure(with: player)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 60, height: 80)
    }
}

// MARK: - PlayerCell
class PlayerCell: UICollectionViewCell {
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 25
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let scoreLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(avatarImageView)
        contentView.addSubview(scoreLabel)
        
        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            avatarImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 50),
            avatarImageView.heightAnchor.constraint(equalToConstant: 50),
            
            scoreLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 4),
            scoreLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scoreLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }
    
    func configure(with player: [String: Any]) {
        if let avatarType = player["avatar"] as? String,
           let avatar = Avatar(rawValue: avatarType) {
            avatarImageView.image = avatar.image
            avatarImageView.backgroundColor = avatar.backgroundColor
        }
        
        scoreLabel.text = "0"
    }
} 