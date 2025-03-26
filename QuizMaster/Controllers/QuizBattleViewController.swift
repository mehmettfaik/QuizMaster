import UIKit
import FirebaseFirestore
import Combine
import FirebaseAuth

class QuizBattleViewController: UIViewController {
    private let category: String
    private let difficulty: String
    private let battleId: String
    private let opponentId: String
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    private var currentQuestion: [String: Any]?
    private var questions: [[String: Any]] = []
    private var currentQuestionIndex = 0
    private var timer: Timer?
    private var timeLeft = 15 // Her soru için 15 saniye
    private var score = 0
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
    
    private lazy var questionLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 18, weight: .medium)
        return label
    }()
    
    private lazy var timerLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 24, weight: .bold)
        return label
    }()
    
    private lazy var scoreLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 18)
        label.text = "Skor: 0"
        return label
    }()
    
    private lazy var answerStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.distribution = .fillEqually
        return stack
    }()
    
    // MARK: - Initialization
    init(category: String, difficulty: String, battleId: String, opponentId: String) {
        self.category = category
        self.difficulty = difficulty
        self.battleId = battleId
        self.opponentId = opponentId
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
        setupCloseButton()
        fetchQuestions()
        observePlayers()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Yarışma"
        
        view.addSubview(containerStackView)
        
        containerStackView.addArrangedSubview(playersCollectionView)
        containerStackView.addArrangedSubview(timerLabel)
        containerStackView.addArrangedSubview(scoreLabel)
        containerStackView.addArrangedSubview(questionLabel)
        containerStackView.addArrangedSubview(answerStackView)
        
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
    
    private func setupCloseButton() {
        let closeButton = UIBarButtonItem(image: UIImage(systemName: "xmark"),
                                        style: .plain,
                                        target: self,
                                        action: #selector(closeButtonTapped))
        closeButton.tintColor = .systemRed
        navigationItem.leftBarButtonItem = closeButton
    }
    
    @objc private func closeButtonTapped() {
        let alert = UIAlertController(
            title: "Yarışmadan Çık",
            message: "Yarışmadan çıkmak istediğinize emin misiniz?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Hayır", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Evet", style: .destructive) { [weak self] _ in
            // Yarışmayı sonlandır ve skoru güncelle
            self?.timer?.invalidate()
            self?.updateScore()
            
            // Battles koleksiyonunda status'ü güncelle
            guard let battleId = self?.battleId else { return }
            self?.db.collection("battles").document(battleId).updateData([
                "status": "ended"
            ]) { error in
                if let error = error {
                    print("Error updating battle status: \(error)")
                }
            }
            
            // Ana sayfaya dön
            self?.navigationController?.popToRootViewController(animated: true)
        })
        
        present(alert, animated: true)
    }
    
    // MARK: - Game Logic
    private func fetchQuestions() {
        // Firestore'dan soruları getir
        db.collection("quizzes")
            .whereField("category", isEqualTo: category)
            .whereField("difficulty", isEqualTo: difficulty)
            .limit(to: 5)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching questions: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self?.questions = documents.map { $0.data() }
                self?.startQuiz()
            }
    }
    
    private func startQuiz() {
        showQuestion(at: currentQuestionIndex)
        startTimer()
    }
    
    private func showQuestion(at index: Int) {
        guard index < questions.count else {
            endQuiz()
            return
        }
        
        currentQuestion = questions[index]
        updateUI()
    }
    
    private func updateUI() {
        guard let question = currentQuestion else { return }
        
        questionLabel.text = question["question"] as? String
        
        // Mevcut cevap butonlarını temizle
        answerStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Cevapları karıştır
        var answers = [(String, Bool)]()
        if let correctAnswer = question["correct_answer"] as? String {
            answers.append((correctAnswer, true))
        }
        if let incorrectAnswers = question["incorrect_answers"] as? [String] {
            answers.append(contentsOf: incorrectAnswers.map { ($0, false) })
        }
        answers.shuffle()
        
        // Cevap butonlarını oluştur
        for (answer, isCorrect) in answers {
            let button = UIButton(type: .system)
            button.setTitle(answer, for: .normal)
            button.backgroundColor = .systemBlue
            button.setTitleColor(.white, for: .normal)
            button.layer.cornerRadius = 10
            button.tag = isCorrect ? 1 : 0
            button.addTarget(self, action: #selector(answerButtonTapped(_:)), for: .touchUpInside)
            answerStackView.addArrangedSubview(button)
            
            // Button height constraint
            button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        }
    }
    
    private func startTimer() {
        timeLeft = 15
        updateTimerLabel()
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.timeLeft -= 1
            self?.updateTimerLabel()
            
            if self?.timeLeft == 0 {
                self?.timer?.invalidate()
                self?.moveToNextQuestion()
            }
        }
    }
    
    private func updateTimerLabel() {
        timerLabel.text = "\(timeLeft)"
    }
    
    @objc private func answerButtonTapped(_ sender: UIButton) {
        timer?.invalidate()
        
        // Doğru cevap kontrolü
        if sender.tag == 1 {
            score += 1
            scoreLabel.text = "Skor: \(score)"
        }
        
        // Skoru Firestore'a kaydet
        updateScore()
        
        // Sonraki soruya geç
        moveToNextQuestion()
    }
    
    private func moveToNextQuestion() {
        currentQuestionIndex += 1
        
        if currentQuestionIndex < questions.count {
            showQuestion(at: currentQuestionIndex)
            startTimer()
        } else {
            endQuiz()
        }
    }
    
    private func updateScore() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("battles").document(battleId).updateData([
            "scores.\(currentUserId)": score
        ]) { error in
            if let error = error {
                print("Error updating score: \(error)")
            }
        }
    }
    
    private func endQuiz() {
        timer?.invalidate()
        
        // Sonuç ekranına geç
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