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
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .primaryPurple
        indicator.hidesWhenStopped = true
        return indicator
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
        
        // Varsayılan değerleri ayarla
        categoryChanged(categorySegmentedControl)
        difficultyChanged(difficultySegmentedControl)
        
        print("Battle ID: \(battleId)") // Debug için
        
        // Battle durumunu dinle
        observeBattleStatus()
    }
    
    private func observeBattleStatus() {
        guard !battleId.isEmpty else {
            showErrorAlert(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Geçersiz yarışma ID"]))
            navigationController?.popViewController(animated: true)
            return
        }
        
        print("Observing battle status for ID: \(battleId)") // Debug için
        
        db.collection("battles").document(battleId)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    self?.showErrorAlert(error)
                    return
                }
                
                guard let data = snapshot?.data(),
                      let status = data["status"] as? String else { return }
                
                print("Battle status: \(status)") // Debug için
                
                if status == "active" {
                    // Yarışma aktif olduğunda QuizBattle ekranına geç
                    let quizBattleVC = QuizBattleViewController(battleId: self?.battleId ?? "")
                    self?.navigationController?.pushViewController(quizBattleVC, animated: true)
                }
            }
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(containerStackView)
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
            
            startButton.heightAnchor.constraint(equalToConstant: 50),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
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
        guard !battleId.isEmpty else {
            showErrorAlert(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Geçersiz yarışma ID"]))
            return
        }
        
        guard let category = selectedCategory,
              let difficulty = selectedDifficulty else { return }
        
        startButton.isEnabled = false
        loadingIndicator.startAnimating()
        
        print("Starting battle with ID: \(battleId)") // Debug için
        
        // Soruları getir
        db.collection("quizzes")
            .whereField("category", isEqualTo: category)
            .whereField("difficulty", isEqualTo: difficulty)
            .limit(to: 5)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    self?.showErrorAlert(error)
                    self?.startButton.isEnabled = true
                    self?.loadingIndicator.stopAnimating()
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self?.showErrorAlert(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Soru bulunamadı"]))
                    self?.startButton.isEnabled = true
                    self?.loadingIndicator.stopAnimating()
                    return
                }
                
                let questions = documents.map { $0.data() }
                
                // Yarışma ayarlarını güncelle
                self?.db.collection("battles").document(self?.battleId ?? "").updateData([
                    "category": category,
                    "difficulty": difficulty,
                    "questions": questions,
                    "status": "active"
                ]) { error in
                    self?.startButton.isEnabled = true
                    self?.loadingIndicator.stopAnimating()
                    
                    if let error = error {
                        self?.showErrorAlert(error)
                    }
                }
            }
    }
} 