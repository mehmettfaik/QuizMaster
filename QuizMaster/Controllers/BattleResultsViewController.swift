import UIKit
import FirebaseFirestore
import FirebaseAuth

class BattleResultsViewController: UIViewController {
    
    private let battleId: String
    private let db = Firestore.firestore()
    
    private lazy var resultLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var scoresStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.alignment = .center
        return stack
    }()
    
    private lazy var playAgainButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Yeni Yarışma", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(playAgainButtonTapped), for: .touchUpInside)
        return button
    }()
    
    init(battleId: String) {
        self.battleId = battleId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCloseButton()
        fetchResults()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Yarışma Sonuçları"
        navigationItem.hidesBackButton = true
        
        view.addSubview(resultLabel)
        view.addSubview(scoresStackView)
        view.addSubview(playAgainButton)
        
        resultLabel.translatesAutoresizingMaskIntoConstraints = false
        scoresStackView.translatesAutoresizingMaskIntoConstraints = false
        playAgainButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            resultLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            resultLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            resultLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            scoresStackView.topAnchor.constraint(equalTo: resultLabel.bottomAnchor, constant: 40),
            scoresStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scoresStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            playAgainButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            playAgainButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            playAgainButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            playAgainButton.heightAnchor.constraint(equalToConstant: 50)
        ])
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
            title: "Sonuçlardan Çık",
            message: "Sonuç ekranından çıkmak istediğinize emin misiniz?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Hayır", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Evet", style: .destructive) { [weak self] _ in
            // Ana sayfaya dön
            self?.navigationController?.popToRootViewController(animated: true)
        })
        
        present(alert, animated: true)
    }
    
    private func fetchResults() {
        db.collection("battles").document(battleId).getDocument { [weak self] snapshot, error in
            if let error = error {
                print("Error fetching results: \(error)")
                return
            }
            
            guard let data = snapshot?.data(),
                  let scores = data["scores"] as? [String: Int] else { return }
            
            // Skorları sırala
            let sortedScores = scores.sorted { $0.value > $1.value }
            
            // Kullanıcı isimlerini al ve sonuçları göster
            self?.fetchUserNames(for: sortedScores) { userNames in
                self?.showResults(scores: sortedScores, userNames: userNames)
            }
        }
    }
    
    private func fetchUserNames(for scores: [(key: String, value: Int)], completion: @escaping ([String: String]) -> Void) {
        let userIds = scores.map { $0.key }
        var userNames: [String: String] = [:]
        let group = DispatchGroup()
        
        for userId in userIds {
            group.enter()
            db.collection("users").document(userId).getDocument { snapshot, error in
                defer { group.leave() }
                
                if let error = error {
                    print("Error fetching user name: \(error)")
                    return
                }
                
                if let data = snapshot?.data(),
                   let name = data["name"] as? String {
                    userNames[userId] = name
                }
            }
        }
        
        group.notify(queue: .main) {
            completion(userNames)
        }
    }
    
    private func showResults(scores: [(key: String, value: Int)], userNames: [String: String]) {
        // Mevcut skorları temizle
        scoresStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Kazananı belirle
        if let winner = scores.first {
            if winner.key == currentUserId {
                resultLabel.text = "Tebrikler! Kazandınız! 🎉"
            } else {
                resultLabel.text = "\(userNames[winner.key] ?? "Rakip") kazandı!"
            }
        }
        
        // Skorları göster
        for (userId, score) in scores {
            let scoreLabel = UILabel()
            scoreLabel.text = "\(userNames[userId] ?? "Bilinmeyen Oyuncu"): \(score) puan"
            scoreLabel.font = .systemFont(ofSize: 18)
            scoreLabel.textAlignment = .center
            
            if userId == currentUserId {
                scoreLabel.textColor = .systemBlue
            }
            
            scoresStackView.addArrangedSubview(scoreLabel)
        }
    }
    
    @objc private func playAgainButtonTapped() {
        // Ana menüye dön
        navigationController?.popToRootViewController(animated: true)
    }
} 