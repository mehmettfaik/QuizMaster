import UIKit
import FirebaseFirestore

class FriendProfileViewController: UIViewController {
    private let userId: String
    private let db = Firestore.firestore()
    private var user: QuizMaster.User?
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.backgroundColor = .clear
        imageView.layer.cornerRadius = 60
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 2
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .black
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let rankView: UIView = {
        let view = UIView()
        view.backgroundColor = .primaryPurple.withAlphaComponent(0.1)
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let rankLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .primaryPurple
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let pointsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .gray
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let achievementsLabel: UILabel = {
        let label = UILabel()
        label.text = "Rozetler"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let achievementsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 16
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
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
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        navigationItem.leftBarButtonItem?.tintColor = .primaryPurple
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(profileImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(rankView)
        rankView.addSubview(rankLabel)
        contentView.addSubview(pointsLabel)
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
            
            profileImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            profileImageView.widthAnchor.constraint(equalToConstant: 120),
            profileImageView.heightAnchor.constraint(equalToConstant: 120),
            
            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            rankView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 16),
            rankView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            rankView.widthAnchor.constraint(equalToConstant: 120),
            rankView.heightAnchor.constraint(equalToConstant: 40),
            
            rankLabel.centerXAnchor.constraint(equalTo: rankView.centerXAnchor),
            rankLabel.centerYAnchor.constraint(equalTo: rankView.centerYAnchor),
            
            pointsLabel.topAnchor.constraint(equalTo: rankView.bottomAnchor, constant: 8),
            pointsLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            achievementsLabel.topAnchor.constraint(equalTo: pointsLabel.bottomAnchor, constant: 32),
            achievementsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            achievementsCollectionView.topAnchor.constraint(equalTo: achievementsLabel.bottomAnchor, constant: 16),
            achievementsCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            achievementsCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            achievementsCollectionView.heightAnchor.constraint(equalToConstant: 400),
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
                  let totalPoints = data["total_points"] as? Int else { return }
            
            DispatchQueue.main.async {
                self.nameLabel.text = name
                self.pointsLabel.text = "\(totalPoints) Puan"
                
                // Avatar ayarla
                if let avatarType = Avatar(rawValue: avatar) {
                    self.profileImageView.image = avatarType.image
                    self.profileImageView.backgroundColor = avatarType.backgroundColor
                    self.profileImageView.layer.borderColor = avatarType.backgroundColor.cgColor
                }
                
                // World rank hesapla
                self.calculateWorldRank(totalPoints: totalPoints)
            }
        }
    }
    
    private func calculateWorldRank(totalPoints: Int) {
        db.collection("users")
            .order(by: "total_points", descending: true)
            .getDocuments { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                if let rank = documents.firstIndex(where: { ($0.data()["id"] as? String) == self?.userId }) {
                    DispatchQueue.main.async {
                        self?.rankLabel.text = "Rank #\(rank + 1)"
                    }
                }
            }
    }
}

extension FriendProfileViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 0 // Achievements will be implemented later
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AchievementCell", for: indexPath) as! AchievementCell
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 16) / 2
        return CGSize(width: width, height: 120)
    }
} 