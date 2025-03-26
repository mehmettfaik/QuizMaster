import UIKit
import FirebaseFirestore

class BattleInvitationViewController: UIViewController {
    private let db = Firestore.firestore()
    private let battleId: String
    private let opponentId: String
    private var selectedCategory: String?
    private var selectedDifficulty: String?
    
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
    
    private let categorySegmentedControl: UISegmentedControl = {
        let items = ["Genel Kültür", "Bilim", "Spor", "Tarih", "Sanat"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.backgroundColor = .systemBackground
        control.selectedSegmentTintColor = .primaryPurple
        return control
    }()
    
    private let difficultySegmentedControl: UISegmentedControl = {
        let items = ["Kolay", "Orta", "Zor"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 1
        control.backgroundColor = .systemBackground
        control.selectedSegmentTintColor = .primaryPurple
        return control
    }()
    
    private let startButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Yarışmayı Başlat", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .primaryPurple
        button.layer.cornerRadius = 20
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        return button
    }()
    
    // MARK: - Initialization
    init(battleId: String, opponentId: String) {
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
        setupActions()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(containerStackView)
        
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
            
            startButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupActions() {
        startButton.addTarget(self, action: #selector(startButtonTapped), for: .touchUpInside)
        categorySegmentedControl.addTarget(self, action: #selector(categoryChanged), for: .valueChanged)
        difficultySegmentedControl.addTarget(self, action: #selector(difficultyChanged), for: .valueChanged)
    }
    
    // MARK: - Actions
    @objc private func categoryChanged(_ sender: UISegmentedControl) {
        let categories = ["general", "science", "sports", "history", "art"]
        selectedCategory = categories[sender.selectedSegmentIndex]
    }
    
    @objc private func difficultyChanged(_ sender: UISegmentedControl) {
        let difficulties = ["easy", "medium", "hard"]
        selectedDifficulty = difficulties[sender.selectedSegmentIndex]
    }
    
    @objc private func startButtonTapped() {
        guard let category = selectedCategory,
              let difficulty = selectedDifficulty else { return }
        
        // Yarışma ayarlarını güncelle
        db.collection("battles").document(battleId).updateData([
            "category": category,
            "difficulty": difficulty,
            "status": "active"
        ]) { [weak self] error in
            if let error = error {
                self?.showErrorAlert(error)
            } else {
                // QuizBattle ekranına geç
                let quizBattleVC = QuizBattleViewController(battleId: self?.battleId ?? "")
                self?.navigationController?.pushViewController(quizBattleVC, animated: true)
            }
        }
    }
} 