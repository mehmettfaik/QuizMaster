import UIKit
import FirebaseFirestore

class FriendProfileViewController: UIViewController {
    private let userId: String
    private let db = Firestore.firestore()
    private var user: QuizMaster.User?
    private var worldRank: Int = 0
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let headerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .primaryPurple.withAlphaComponent(0.1)
        view.layer.cornerRadius = 30
        return view
    }()
    
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.backgroundColor = .clear
        imageView.layer.cornerRadius = 50
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 3
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.translatesAutoresizingMaskIntoConstraints = false
        // Add shadow to container
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowOffset = CGSize(width: 0, height: 4)
        imageView.layer.shadowRadius = 8
        imageView.layer.shadowOpacity = 0.1
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .primaryPurple
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let statsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let rankView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 15
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 6
        view.layer.shadowOpacity = 0.1
        return view
    }()
    
    private let rankLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .primaryPurple
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let pointsView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 15
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 6
        view.layer.shadowOpacity = 0.1
        return view
    }()
    
    private let pointsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .primaryPurple
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let achievementsLabel: UILabel = {
        let label = UILabel()
        label.text = "Rozetler"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .primaryPurple
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let achievementsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 20
        layout.minimumInteritemSpacing = 20
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.isScrollEnabled = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    init(userId: String) {
        self.userId = userId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
        loadUserProfile()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        title = "Profil"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left")?.withConfiguration(
                UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
            ),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        navigationItem.leftBarButtonItem?.tintColor = .primaryPurple
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(headerView)
        headerView.addSubview(profileImageView)
        headerView.addSubview(nameLabel)
        headerView.addSubview(statsStackView)
        
        statsStackView.addArrangedSubview(rankView)
        rankView.addSubview(rankLabel)
        
        statsStackView.addArrangedSubview(pointsView)
        pointsView.addSubview(pointsLabel)
        
        contentView.addSubview(achievementsLabel)
        contentView.addSubview(achievementsCollectionView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            profileImageView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            profileImageView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 30),
            profileImageView.widthAnchor.constraint(equalToConstant: 100),
            profileImageView.heightAnchor.constraint(equalToConstant: 100),
            
            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            
            statsStackView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 20),
            statsStackView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            statsStackView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -30),
            
            rankView.widthAnchor.constraint(equalToConstant: 130),
            rankView.heightAnchor.constraint(equalToConstant: 50),
            
            rankLabel.centerXAnchor.constraint(equalTo: rankView.centerXAnchor),
            rankLabel.centerYAnchor.constraint(equalTo: rankView.centerYAnchor),
            
            pointsView.widthAnchor.constraint(equalToConstant: 130),
            pointsView.heightAnchor.constraint(equalToConstant: 50),
            
            pointsLabel.centerXAnchor.constraint(equalTo: pointsView.centerXAnchor),
            pointsLabel.centerYAnchor.constraint(equalTo: pointsView.centerYAnchor),
            
            achievementsLabel.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 30),
            achievementsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            achievementsCollectionView.topAnchor.constraint(equalTo: achievementsLabel.bottomAnchor, constant: 20),
            achievementsCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            achievementsCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            achievementsCollectionView.heightAnchor.constraint(equalToConstant: 600),
            achievementsCollectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupCollectionView() {
        achievementsCollectionView.delegate = self
        achievementsCollectionView.dataSource = self
        achievementsCollectionView.register(AchievementCell.self, forCellWithReuseIdentifier: "AchievementCell")
    }
    
    @objc private func backTapped() {
        dismiss(animated: true)
    }
    
    private func loadUserProfile() {
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self,
                  let data = snapshot?.data(),
                  let name = data["name"] as? String,
                  let avatar = data["avatar"] as? String,
                  let totalPoints = data["total_points"] as? Int,
                  let quizzesPlayed = data["quizzes_played"] as? Int,
                  let quizzesWon = data["quizzes_won"] as? Int else { return }
            
            // Create user object
            self.user = User(
                id: self.userId,
                email: data["email"] as? String ?? "",
                name: name,
                avatar: avatar,
                totalPoints: totalPoints,
                quizzesPlayed: quizzesPlayed,
                quizzesWon: quizzesWon,
                language: data["language"] as? String ?? "tr",
                categoryStats: [:],
                isOnline: data["is_online"] as? Bool ?? false,
                lastOnline: (data["last_online"] as? Timestamp)?.dateValue() ?? Date()
            )
            
            DispatchQueue.main.async {
                self.nameLabel.text = name
                self.pointsLabel.text = String(format: "%d %@", totalPoints, LanguageManager.shared.localizedString(for: "point"))
                
                // Avatar ayarla
                if let avatarType = Avatar(rawValue: avatar) {
                    self.profileImageView.image = avatarType.image
                    self.profileImageView.backgroundColor = avatarType.backgroundColor
                    self.profileImageView.layer.borderColor = avatarType.backgroundColor.cgColor
                }
                
                // World rank hesapla
                self.calculateWorldRank(totalPoints: totalPoints)
                
                // Rozetleri hesapla
                self.calculateAchievements(quizzesPlayed: quizzesPlayed, quizzesWon: quizzesWon, totalPoints: totalPoints)
            }
        }
    }
    
    private func calculateWorldRank(totalPoints: Int) {
        db.collection("users")
            .order(by: "total_points", descending: true)
            .getDocuments { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                if let rank = documents.firstIndex(where: { $0.documentID == self?.userId }) {
                    DispatchQueue.main.async {
                        self?.worldRank = rank + 1
                        self?.rankLabel.text = "Rank 🏆\(rank + 1)"
                        self?.calculateAchievements(
                            quizzesPlayed: self?.user?.quizzesPlayed ?? 0,
                            quizzesWon: self?.user?.quizzesWon ?? 0,
                            totalPoints: self?.user?.totalPoints ?? 0
                        )
                    }
                }
            }
    }
    
    private func calculateAchievements(quizzesPlayed: Int, quizzesWon: Int, totalPoints: Int) {
        var badges: [AchievementBadge] = [
            // Points Badges
            AchievementBadge(
                id: "points_100",
                title: LanguageManager.shared.localizedString(for: "rookie"),
                description: LanguageManager.shared.localizedString(for: "collect_100_points"),
                icon: "medal.fill",
                isUnlocked: totalPoints >= 100,
                progress: min(Double(totalPoints) / 100.0, 1.0),
                requirement: 100,
                currentValue: totalPoints
            ),
            AchievementBadge(
                id: "points_500",
                title: LanguageManager.shared.localizedString(for: "expert"),
                description: LanguageManager.shared.localizedString(for: "collect_500_points"),
                icon: "bolt.circle.fill",
                isUnlocked: totalPoints >= 500,
                progress: min(Double(totalPoints) / 500.0, 1.0),
                requirement: 500,
                currentValue: totalPoints
            ),
            AchievementBadge(
                id: "points_1000",
                title: LanguageManager.shared.localizedString(for: "legend"),
                description: LanguageManager.shared.localizedString(for: "collect_1000_points"),
                icon: "star.square.fill",
                isUnlocked: totalPoints >= 1000,
                progress: min(Double(totalPoints) / 1000.0, 1.0),
                requirement: 1000,
                currentValue: totalPoints
            ),
            
            // Quiz Count Badges
            AchievementBadge(
                id: "quiz_5",
                title: LanguageManager.shared.localizedString(for: "quiz_lover"),
                description: LanguageManager.shared.localizedString(for: "complete_5_quizzes"),
                icon: "checkmark.circle.fill",
                isUnlocked: quizzesPlayed >= 5,
                progress: min(Double(quizzesPlayed) / 5.0, 1.0),
                requirement: 5,
                currentValue: quizzesPlayed
            ),
            AchievementBadge(
                id: "quiz_20",
                title: LanguageManager.shared.localizedString(for: "quiz_pro"),
                description: LanguageManager.shared.localizedString(for: "complete_20_quizzes"),
                icon: "trophy.fill",
                isUnlocked: quizzesPlayed >= 20,
                progress: min(Double(quizzesPlayed) / 20.0, 1.0),
                requirement: 20,
                currentValue: quizzesPlayed
            ),
            
            // Rank Badge
            AchievementBadge(
                id: "rank_top_10",
                title: LanguageManager.shared.localizedString(for: "elite"),
                description: LanguageManager.shared.localizedString(for: "reach_top_10"),
                icon: "crown.fill",
                isUnlocked: worldRank <= 10,
                progress: worldRank <= 10 ? 1.0 : 0.0,
                requirement: 10,
                currentValue: worldRank
            )
        ]
        
        self.achievements = badges
        self.achievementsCollectionView.reloadData()
    }
    
    private var achievements: [AchievementBadge] = []
}

extension FriendProfileViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return achievements.isEmpty ? 1 : achievements.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AchievementCell", for: indexPath) as! AchievementCell
        
        if achievements.isEmpty {
            cell.configureAsPlaceholder()
        } else {
            let achievement = achievements[indexPath.item]
            cell.configure(with: achievement)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let spacing: CGFloat = 20
        let availableWidth = collectionView.bounds.width - spacing
        let width = availableWidth / 2
        return CGSize(width: width, height: 180)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !achievements.isEmpty else { return }
        
        let achievement = achievements[indexPath.item]
        let alert = UIAlertController(
            title: achievement.title,
            message: """
            \(achievement.description)

            \(LanguageManager.shared.localizedString(for: "achievement_progress")): \(achievement.currentValue)/\(achievement.requirement)
            """,

            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: LanguageManager.shared.localizedString(for: "ok"), style: .default))
        present(alert, animated: true)
    }
} 
