import UIKit
import FirebaseFirestore
import Combine

class OnlineBattleViewController: UIViewController {
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    private var currentUserId: String?
    private var currentBattleId: String?
    private var timer: Timer?
    private var remainingTime: Int = 30
    
    // MARK: - UI Components
    private let containerStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .primaryPurple
        label.textAlignment = .center
        label.text = "Canlı Yarışma"
        return label
    }()
    
    private let onlineUsersCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 16
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    private let createBattleButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Yeni Yarışma Oluştur", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .primaryPurple
        button.layer.cornerRadius = 20
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let timerLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 36, weight: .bold)
        label.textColor = .primaryPurple
        label.isHidden = true
        return label
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .primaryPurple
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
        setupActions()
        getCurrentUser()
        observeOnlineUsers()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
        if let battleId = currentBattleId {
            leaveBattle(battleId: battleId)
        }
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Canlı Yarışma"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Kapat",
            style: .done,
            target: self,
            action: #selector(closeTapped)
        )
        
        view.addSubview(containerStackView)
        containerStackView.addArrangedSubview(statusLabel)
        containerStackView.addArrangedSubview(onlineUsersCollectionView)
        containerStackView.addArrangedSubview(createBattleButton)
        containerStackView.addArrangedSubview(timerLabel)
        containerStackView.addArrangedSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            containerStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            containerStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            containerStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            onlineUsersCollectionView.heightAnchor.constraint(equalToConstant: 400),
            onlineUsersCollectionView.widthAnchor.constraint(equalTo: containerStackView.widthAnchor),
            
            createBattleButton.heightAnchor.constraint(equalToConstant: 50),
            createBattleButton.widthAnchor.constraint(equalTo: containerStackView.widthAnchor, constant: -40)
        ])
    }
    
    private func setupCollectionView() {
        onlineUsersCollectionView.delegate = self
        onlineUsersCollectionView.dataSource = self
        onlineUsersCollectionView.register(OnlineUserCell.self, forCellWithReuseIdentifier: "OnlineUserCell")
    }
    
    private func setupActions() {
        createBattleButton.addTarget(self, action: #selector(createBattleTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    @objc private func createBattleTapped() {
        createBattle()
    }
    
    // MARK: - Firebase Operations
    private func getCurrentUser() {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }
        currentUserId = userId
        updateUserOnlineStatus(isOnline: true)
    }
    
    private func updateUserOnlineStatus(isOnline: Bool) {
        guard let userId = currentUserId else { return }
        
        let data: [String: Any] = [
            "isOnline": isOnline,
            "lastSeen": Timestamp(date: Date())
        ]
        
        db.collection("users").document(userId).updateData(data)
    }
    
    private func observeOnlineUsers() {
        db.collection("users")
            .whereField("isOnline", isEqualTo: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                // Online kullanıcıları güncelle
                self?.onlineUsersCollectionView.reloadData()
            }
    }
    
    private func createBattle() {
        guard let userId = currentUserId else { return }
        
        let battleData: [String: Any] = [
            "createdBy": userId,
            "status": "waiting",
            "createdAt": Timestamp(date: Date()),
            "players": [userId],
            "maxPlayers": 4
        ]
        
        var ref: DocumentReference? = nil
        ref = db.collection("battles").addDocument(data: battleData) { [weak self] error in
            if let error = error {
                self?.showErrorAlert(error)
            } else if let battleId = ref?.documentID {
                self?.currentBattleId = battleId
                self?.startWaitingForPlayers(battleId: battleId)
            }
        }
    }
    
    private func joinBattle(battleId: String) {
        guard let userId = currentUserId else { return }
        
        db.collection("battles").document(battleId).updateData([
            "players": FieldValue.arrayUnion([userId])
        ]) { [weak self] error in
            if let error = error {
                self?.showErrorAlert(error)
            } else {
                self?.currentBattleId = battleId
                self?.startWaitingForPlayers(battleId: battleId)
            }
        }
    }
    
    private func leaveBattle(battleId: String) {
        guard let userId = currentUserId else { return }
        
        db.collection("battles").document(battleId).updateData([
            "players": FieldValue.arrayRemove([userId])
        ])
    }
    
    private func startWaitingForPlayers(battleId: String) {
        remainingTime = 30
        timerLabel.isHidden = false
        updateTimerLabel()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            
            self.remainingTime -= 1
            self.updateTimerLabel()
            
            if self.remainingTime <= 0 {
                timer.invalidate()
                self.startBattle(battleId: battleId)
            }
        }
    }
    
    private func updateTimerLabel() {
        timerLabel.text = "Oyun başlayana kalan süre: \(remainingTime)"
    }
    
    private func startBattle(battleId: String) {
        db.collection("battles").document(battleId).updateData([
            "status": "active"
        ]) { [weak self] error in
            if let error = error {
                self?.showErrorAlert(error)
            } else {
                self?.navigateToQuizBattle(battleId: battleId)
            }
        }
    }
    
    private func navigateToQuizBattle(battleId: String) {
        let quizBattleVC = QuizBattleViewController(battleId: battleId)
        navigationController?.pushViewController(quizBattleVC, animated: true)
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension OnlineBattleViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10 // Örnek sayı, gerçek veriye göre güncellenecek
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OnlineUserCell", for: indexPath) as! OnlineUserCell
        // Cell'i configure et
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 48) / 2
        return CGSize(width: width, height: width * 1.2)
    }
}

// MARK: - OnlineUserCell
class OnlineUserCell: UICollectionViewCell {
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 30
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let statusIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGreen
        view.layer.cornerRadius = 5
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .systemGray6
        layer.cornerRadius = 12
        
        contentView.addSubview(avatarImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(statusIndicator)
        
        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            avatarImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 60),
            avatarImageView.heightAnchor.constraint(equalToConstant: 60),
            
            nameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            
            statusIndicator.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            statusIndicator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            statusIndicator.widthAnchor.constraint(equalToConstant: 10),
            statusIndicator.heightAnchor.constraint(equalToConstant: 10)
        ])
    }
    
    func configure(with user: [String: Any]) {
        nameLabel.text = user["name"] as? String
        if let avatarType = user["avatar"] as? String,
           let avatar = Avatar(rawValue: avatarType) {
            avatarImageView.image = avatar.image
            avatarImageView.backgroundColor = avatar.backgroundColor
        }
    }
} 