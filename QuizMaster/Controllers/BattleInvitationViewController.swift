import UIKit
import FirebaseFirestore

class BattleInvitationViewController: UIViewController {
    private let db = Firestore.firestore()
    private let battleId: String
    private let opponentId: String
    private let isCreator: Bool
    private var selectedCategory: String?
    private var selectedDifficulty: String?
    private var categories: [String] = []
    
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
        label.text = "Yarışma Ayarları"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .primaryPurple
        label.textAlignment = .center
        return label
    }()
    
    private lazy var waitingLabel: UILabel = {
        let label = UILabel()
        label.text = "Rakibiniz oyun ayarlarını seçiyor..."
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = isCreator
        return label
    }()
    
    private lazy var blurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .dark)
        let view = UIVisualEffectView(effect: blurEffect)
        view.isHidden = isCreator
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let categorySegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl()
        control.backgroundColor = .systemBackground
        control.selectedSegmentTintColor = .systemBlue
        return control
    }()
    
    private let difficultySegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["Kolay", "Orta", "Zor"])
        control.backgroundColor = .systemBackground
        control.selectedSegmentTintColor = .systemBlue
        control.selectedSegmentIndex = 0
        return control
    }()
    
    private let startButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Yarışmayı Başlat", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.isEnabled = false
        return button
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .primaryPurple
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - Initialization
    init(battleId: String, opponentId: String, isCreator: Bool) {
        self.battleId = battleId
        self.opponentId = opponentId
        self.isCreator = isCreator
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchCategories()
        setupUI()
        setupActions()
        
        if !isCreator {
            // İsteği kabul eden kullanıcı için blur efekti ve bekleme mesajı
            blurView.isHidden = false
            waitingLabel.isHidden = false
            categorySegmentedControl.isEnabled = false
            difficultySegmentedControl.isEnabled = false
            startButton.isEnabled = false
        }
        
        // Battle durumunu dinle
        observeBattleStatus()
    }
    
    private func fetchCategories() {
        db.collection("categories").getDocuments { [weak self] snapshot, error in
            if let error = error {
                print("Error fetching categories: \(error)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            self?.categories = documents.compactMap { document in
                return document.data()["name"] as? String
            }
            
            DispatchQueue.main.async {
                self?.updateCategorySegmentedControl()
            }
        }
    }
    
    private func updateCategorySegmentedControl() {
        // Mevcut segmentleri temizle
        categorySegmentedControl.removeAllSegments()
        
        // Yeni kategorileri ekle
        for (index, category) in categories.enumerated() {
            categorySegmentedControl.insertSegment(withTitle: category, at: index, animated: false)
        }
        
        // İlk kategoriyi seç
        if categories.count > 0 {
            categorySegmentedControl.selectedSegmentIndex = 0
        }
    }
    
    private func observeBattleStatus() {
        guard !battleId.isEmpty else {
            print("Error: Battle ID is empty")
            return
        }
        
        print("Observing battle status for battle ID: \(battleId)")
        
        db.collection("battles").document(battleId)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error observing battle status: \(error)")
                    return
                }
                
                guard let data = snapshot?.data(),
                      let status = data["status"] as? String else {
                    print("Error: Invalid battle data")
                    return
                }
                
                if status == "started" {
                    // Yarışma başladı, QuizBattleViewController'a geç
                    if let category = data["category"] as? String,
                       let difficulty = data["difficulty"] as? String {
                        DispatchQueue.main.async {
                            let quizBattleVC = QuizBattleViewController(category: category,
                                                                       difficulty: difficulty,
                                                                       battleId: self?.battleId ?? "",
                                                                       opponentId: self?.opponentId ?? "")
                            self?.navigationController?.pushViewController(quizBattleVC, animated: true)
                        }
                    }
                }
            }
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(containerStackView)
        view.addSubview(blurView)
        view.addSubview(waitingLabel)
        view.addSubview(loadingIndicator)
        
        let categoryLabel = UILabel()
        categoryLabel.text = "Kategori Seçin"
        categoryLabel.font = .systemFont(ofSize: 18, weight: .medium)
        
        let difficultyLabel = UILabel()
        difficultyLabel.text = "Zorluk Seviyesi"
        difficultyLabel.font = .systemFont(ofSize: 18, weight: .medium)
        
        containerStackView.addArrangedSubview(titleLabel)
        containerStackView.addArrangedSubview(UIView()) // Spacer
        containerStackView.addArrangedSubview(categoryLabel)
        containerStackView.addArrangedSubview(categorySegmentedControl)
        containerStackView.addArrangedSubview(UIView()) // Spacer
        containerStackView.addArrangedSubview(difficultyLabel)
        containerStackView.addArrangedSubview(difficultySegmentedControl)
        containerStackView.addArrangedSubview(UIView()) // Spacer
        containerStackView.addArrangedSubview(startButton)
        
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            containerStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            containerStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            blurView.topAnchor.constraint(equalTo: view.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            waitingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            waitingLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            waitingLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            waitingLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            startButton.heightAnchor.constraint(equalToConstant: 50),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        waitingLabel.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupActions() {
        startButton.addTarget(self, action: #selector(startButtonTapped), for: .touchUpInside)
        categorySegmentedControl.addTarget(self, action: #selector(categoryChanged), for: .valueChanged)
        difficultySegmentedControl.addTarget(self, action: #selector(difficultyChanged), for: .valueChanged)
    }
    
    // MARK: - Actions
    @objc private func categoryChanged(_ sender: UISegmentedControl) {
        guard sender.selectedSegmentIndex >= 0,
              sender.selectedSegmentIndex < categories.count else { return }
        selectedCategory = categories[sender.selectedSegmentIndex]
    }
    
    @objc private func difficultyChanged(_ sender: UISegmentedControl) {
        let difficulties = ["easy", "medium", "hard"]
        selectedDifficulty = difficulties[sender.selectedSegmentIndex]
    }
    
    @objc private func startButtonTapped() {
        guard let selectedCategory = categories[safe: categorySegmentedControl.selectedSegmentIndex] else { return }
        let difficulties = ["easy", "medium", "hard"]
        let selectedDifficulty = difficulties[difficultySegmentedControl.selectedSegmentIndex]
        
        // Yarışma dokümanını güncelle
        db.collection("battles").document(battleId).updateData([
            "status": "started",
            "category": selectedCategory,
            "difficulty": selectedDifficulty
        ]) { [weak self] error in
            if let error = error {
                print("Error updating battle: \(error)")
                return
            }
            
            // QuizBattleViewController'a geç
            DispatchQueue.main.async {
                let quizBattleVC = QuizBattleViewController(category: selectedCategory,
                                                           difficulty: selectedDifficulty,
                                                           battleId: self?.battleId ?? "",
                                                           opponentId: self?.opponentId ?? "")
                self?.navigationController?.pushViewController(quizBattleVC, animated: true)
            }
        }
    }
}

// Array extension for safe index access
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
} 