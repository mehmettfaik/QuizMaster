import UIKit
import FirebaseFirestore

class BattleResultsViewController: UIViewController {
    private let battleId: String
    private let db = Firestore.firestore()
    private var results: [[String: Any]] = []
    
    // MARK: - UI Components
    private let containerStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Yarışma Sonuçları"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .primaryPurple
        label.textAlignment = .center
        return label
    }()
    
    private let resultsTableView: UITableView = {
        let table = UITableView()
        table.backgroundColor = .clear
        table.separatorStyle = .none
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    private let playAgainButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Yeni Yarışma", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .primaryPurple
        button.layer.cornerRadius = 20
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        return button
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
        setupTableView()
        loadResults()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        navigationItem.hidesBackButton = true
        
        view.addSubview(containerStackView)
        
        containerStackView.addArrangedSubview(titleLabel)
        containerStackView.addArrangedSubview(resultsTableView)
        containerStackView.addArrangedSubview(playAgainButton)
        
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            containerStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            containerStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            containerStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            resultsTableView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.6),
            playAgainButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        playAgainButton.addTarget(self, action: #selector(playAgainTapped), for: .touchUpInside)
    }
    
    private func setupTableView() {
        resultsTableView.delegate = self
        resultsTableView.dataSource = self
        resultsTableView.register(ResultCell.self, forCellReuseIdentifier: "ResultCell")
    }
    
    // MARK: - Data Loading
    private func loadResults() {
        db.collection("battles").document(battleId)
            .collection("scores")
            .order(by: "score", descending: true)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    self?.showErrorAlert(error)
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                // Kullanıcı bilgilerini yükle
                let group = DispatchGroup()
                var tempResults: [[String: Any]] = []
                
                for document in documents {
                    group.enter()
                    let userId = document.documentID
                    let score = document.data()["score"] as? Int ?? 0
                    
                    self?.db.collection("users").document(userId).getDocument { snapshot, error in
                        defer { group.leave() }
                        
                        if let userData = snapshot?.data() {
                            var result = userData
                            result["score"] = score
                            tempResults.append(result)
                        }
                    }
                }
                
                group.notify(queue: .main) {
                    self?.results = tempResults.sorted { ($0["score"] as? Int ?? 0) > ($1["score"] as? Int ?? 0) }
                    self?.resultsTableView.reloadData()
                    self?.updateAchievements()
                }
            }
    }
    
    private func updateAchievements() {
        guard let userId = UserDefaults.standard.string(forKey: "userId"),
              let userResult = results.first(where: { ($0["id"] as? String) == userId }),
              let userScore = userResult["score"] as? Int else { return }
        
        // Başarı durumuna göre achievement ekle
        if userScore == results.count { // Tam puan
            addAchievement("perfect_score")
        }
        if results.first?["id"] as? String == userId { // Birinci olma
            addAchievement("battle_winner")
        }
    }
    
    private func addAchievement(_ type: String) {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }
        
        db.collection("users").document(userId)
            .collection("achievements")
            .document(type)
            .setData([
                "type": type,
                "earnedAt": Timestamp(date: Date())
            ])
    }
    
    // MARK: - Actions
    @objc private func playAgainTapped() {
        // Yeni bir yarışma başlat
        navigationController?.popToRootViewController(animated: true)
    }
}

// MARK: - UITableView DataSource & Delegate
extension BattleResultsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ResultCell", for: indexPath) as! ResultCell
        let result = results[indexPath.row]
        cell.configure(with: result, rank: indexPath.row + 1)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}

// MARK: - ResultCell
class ResultCell: UITableViewCell {
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let rankLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .primaryPurple
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 25
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let scoreLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .primaryPurple
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        
        contentView.addSubview(containerView)
        containerView.addSubview(rankLabel)
        containerView.addSubview(avatarImageView)
        containerView.addSubview(nameLabel)
        containerView.addSubview(scoreLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            rankLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            rankLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            rankLabel.widthAnchor.constraint(equalToConstant: 30),
            
            avatarImageView.leadingAnchor.constraint(equalTo: rankLabel.trailingAnchor, constant: 16),
            avatarImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 50),
            avatarImageView.heightAnchor.constraint(equalToConstant: 50),
            
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 16),
            nameLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            scoreLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            scoreLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
    }
    
    func configure(with result: [String: Any], rank: Int) {
        rankLabel.text = "\(rank)"
        nameLabel.text = result["name"] as? String
        scoreLabel.text = "\(result["score"] as? Int ?? 0) puan"
        
        if let avatarType = result["avatar"] as? String,
           let avatar = Avatar(rawValue: avatarType) {
            avatarImageView.image = avatar.image
            avatarImageView.backgroundColor = avatar.backgroundColor
        }
        
        // Birinci için özel stil
        if rank == 1 {
            containerView.backgroundColor = .primaryPurple.withAlphaComponent(0.1)
            rankLabel.textColor = .systemYellow
        } else {
            containerView.backgroundColor = .systemGray6
            rankLabel.textColor = .primaryPurple
        }
    }
} 