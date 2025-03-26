import UIKit
import FirebaseFirestore
import Combine
import FirebaseAuth
import FirebaseFirestoreFirebase

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
    private var questionListener: ListenerRegistration?
    private var currentQuestionData: [String: Any]?
    private var isAnswered = false
    
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
        checkBattleStatus()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
        updateUserStatus(isPlaying: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUserStatus(isPlaying: true)
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
    
    // MARK: - Battle Management
    private func checkBattleStatus() {
        db.collection("battles").document(battleId).getDocument { [weak self] snapshot, error in
            if let error = error {
                print("Error checking battle status: \(error)")
                self?.navigationController?.popToRootViewController(animated: true)
                return
            }
            
            guard let data = snapshot?.data(),
                  let status = data["status"] as? String,
                  status == "started" else {
                print("Battle is not in valid state")
                self?.navigationController?.popToRootViewController(animated: true)
                return
            }
            
            // Battle geçerliyse soruları getir ve oyuncuları gözlemle
            self?.fetchQuestions()
            self?.observePlayers()
            self?.observeBattleStatus()
        }
    }
    
    private func updateUserStatus(isPlaying: Bool) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(currentUserId).updateData([
            "isPlaying": isPlaying,
            "currentBattleId": isPlaying ? self.battleId : nil
        ])
    }
    
    private func observeBattleStatus() {
        db.collection("battles").document(battleId)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error observing battle status: \(error)")
                    return
                }
                
                guard let data = snapshot?.data(),
                      let status = data["status"] as? String else { return }
                
                if status == "cancelled" {
                    DispatchQueue.main.async {
                        self?.handleBattleCancellation()
                    }
                }
            }
    }
    
    private func handleBattleCancellation() {
        timer?.invalidate()
        
        let alert = UIAlertController(
            title: "Yarışma İptal Edildi",
            message: "Rakibiniz yarışmadan ayrıldı.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Tamam", style: .default) { [weak self] _ in
            self?.navigationController?.popToRootViewController(animated: true)
        })
        
        present(alert, animated: true)
    }
    
    @objc private func closeButtonTapped() {
        let alert = UIAlertController(
            title: "Yarışmadan Çık",
            message: "Yarışmadan çıkmak istediğinize emin misiniz? Rakibiniz kazanacak.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Hayır", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Evet", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            // Timer'ı durdur
            self.timer?.invalidate()
            
            // Rakibe otomatik olarak kazandır
            guard let currentUserId = Auth.auth().currentUser?.uid else { return }
            let opponentScore = 5 // Maksimum skor
            
            self.db.collection("battles").document(self.battleId).updateData([
                "status": "ended",
                "endedAt": Timestamp(),
                "endedBy": currentUserId,
                "scores.\(self.opponentId)": opponentScore,
                "scores.\(currentUserId)": self.score
            ]) { error in
                if let error = error {
                    print("Error ending battle: \(error)")
                }
                
                // Ana sayfaya dön
                self.navigationController?.popToRootViewController(animated: true)
            }
        })
        
        present(alert, animated: true)
    }
    
    // MARK: - Game Logic
    private func fetchQuestions() {
        // Format category name for Firestore path
        let formattedCategory = category.components(separatedBy: " ")
            .enumerated()
            .map { index, word in
                if index == 0 {
                    return word.lowercased()
                }
                return word.prefix(1).uppercased() + word.dropFirst().lowercased()
            }
            .joined()
        
        // Firestore'dan soruları getir
        db.collection("aaaa")
            .document(formattedCategory)
            .collection("questions")
            .whereField("difficulty", isEqualTo: difficulty.lowercased())
            .limit(to: 5)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching questions: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self?.questions = documents.map { $0.data() }
                
                // Eğer yarışmayı oluşturan kullanıcıysak, soruları battle dökümanına ekle
                if let currentUserId = Auth.auth().currentUser?.uid,
                   currentUserId == self?.opponentId {
                    self?.db.collection("battles").document(self?.battleId ?? "").updateData([
                        "questions": self?.questions ?? [],
                        "currentQuestionIndex": 0,
                        "startTime": Timestamp()
                    ]) { error in
                        if let error = error {
                            print("Error updating battle with questions: \(error)")
                            return
                        }
                        self?.startQuestionSync()
                    }
                } else {
                    self?.startQuestionSync()
                }
            }
    }
    
    private func startQuestionSync() {
        // Mevcut listener'ı temizle
        questionListener?.remove()
        
        // Battle'daki soru değişikliklerini dinle
        questionListener = db.collection("battles").document(battleId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self,
                      let data = snapshot?.data(),
                      let questions = data["questions"] as? [[String: Any]],
                      let currentIndex = data["currentQuestionIndex"] as? Int,
                      currentIndex < questions.count else {
                    return
                }
                
                // Yeni soru geldiğinde
                let questionData = questions[currentIndex]
                if self.currentQuestionData != questionData {
                    self.currentQuestionData = questionData
                    self.isAnswered = false
                    self.showSyncedQuestion(questionData)
                }
                
                // Cevapları kontrol et
                if let answers = data["answers"] as? [String: Any],
                   let winner = answers["winner"] as? String,
                   !self.isAnswered {
                    self.handleAnswer(winner: winner)
                }
            }
    }
    
    private func showSyncedQuestion(_ questionData: [String: Any]) {
        DispatchQueue.main.async {
            self.currentQuestion = questionData
            self.updateUI()
            self.startTimer()
        }
    }
    
    private func handleAnswer(winner: String) {
        guard !isAnswered else { return }
        isAnswered = true
        
        let currentUserId = Auth.auth().currentUser?.uid ?? ""
        if winner == currentUserId {
            score += 1
            scoreLabel.text = "Skor: \(score)"
        }
        
        // Tüm butonları devre dışı bırak
        answerStackView.arrangedSubviews.forEach { view in
            if let button = view as? UIButton {
                button.isEnabled = false
            }
        }
        
        // 2 saniye sonra sonraki soruya geç
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.moveToNextQuestion()
        }
    }
    
    @objc private func answerButtonTapped(_ sender: UIButton) {
        guard !isAnswered,
              let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        timer?.invalidate()
        isAnswered = true
        
        // Cevabı Firestore'a kaydet
        if sender.tag == 1 { // Doğru cevap
            db.collection("battles").document(battleId).updateData([
                "answers": [
                    "winner": currentUserId,
                    "answeredAt": Timestamp()
                ]
            ])
        }
    }
    
    private func moveToNextQuestion() {
        guard let currentUserId = Auth.auth().currentUser?.uid,
              currentUserId == opponentId else { return }
        
        currentQuestionIndex += 1
        
        if currentQuestionIndex < questions.count {
            db.collection("battles").document(battleId).updateData([
                "currentQuestionIndex": currentQuestionIndex,
                "answers": [:] // Cevapları sıfırla
            ])
        } else {
            endQuiz()
        }
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
            guard let self = self else { return }
            
            self.timeLeft -= 1
            self.updateTimerLabel()
            
            if self.timeLeft == 0 && !self.isAnswered {
                self.timer?.invalidate()
                self.isAnswered = true
                
                // Süre dolduğunda sonraki soruya geç
                if Auth.auth().currentUser?.uid == self.opponentId {
                    self.moveToNextQuestion()
                }
            }
        }
    }
    
    private func updateTimerLabel() {
        timerLabel.text = "\(timeLeft)"
    }
    
    private func endQuiz() {
        timer?.invalidate()
        
        // Battle'ı bitir
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("battles").document(battleId).updateData([
            "status": "ended",
            "endedAt": Timestamp(),
            "endedBy": currentUserId,
            "scores.\(currentUserId)": score
        ]) { [weak self] error in
            if let error = error {
                print("Error ending battle: \(error)")
            }
            
            // Sonuç ekranına geç
            if let self = self {
                let resultsVC = BattleResultsViewController(battleId: self.battleId)
                self.navigationController?.pushViewController(resultsVC, animated: true)
            }
        }
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