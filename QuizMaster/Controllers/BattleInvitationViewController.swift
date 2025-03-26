import UIKit
import FirebaseFirestore
import FirebaseAuth

class BattleInvitationViewController: UIViewController {
    private let db = Firestore.firestore()
    private let battleId: String
    private let opponentId: String
    private let isCreator: Bool
    private var categories: [String] = []
    
    // MARK: - UI Components
    private let containerStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .fill
        stack.distribution = .fill
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
    
    private let categoryLabel: UILabel = {
        let label = UILabel()
        label.text = "Kategori Seçin"
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .left
        return label
    }()
    
    private let categoryPickerView: UIPickerView = {
        let picker = UIPickerView()
        picker.backgroundColor = .systemBackground
        return picker
    }()
    
    private let difficultyLabel: UILabel = {
        let label = UILabel()
        label.text = "Zorluk Seviyesi"
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .left
        return label
    }()
    
    private lazy var difficultySegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["Kolay", "Orta", "Zor"])
        control.backgroundColor = .systemBackground
        control.selectedSegmentTintColor = .systemBlue
        control.selectedSegmentIndex = 0
        control.isEnabled = isCreator
        return control
    }()
    
    private lazy var startButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Yarışmayı Başlat", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.isEnabled = isCreator
        return button
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
        setupUI()
        setupPickerView()
        setupActions()
        setupCloseButton()
        fetchCategories()
        
        if !isCreator {
            observeBattleStatus()
        }
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        navigationItem.hidesBackButton = true
        
        view.addSubview(containerStackView)
        
        containerStackView.addArrangedSubview(titleLabel)
        containerStackView.addArrangedSubview(UIView()) // Spacer
        containerStackView.addArrangedSubview(categoryLabel)
        containerStackView.addArrangedSubview(categoryPickerView)
        containerStackView.addArrangedSubview(UIView()) // Spacer
        containerStackView.addArrangedSubview(difficultyLabel)
        containerStackView.addArrangedSubview(difficultySegmentedControl)
        containerStackView.addArrangedSubview(UIView()) // Spacer
        containerStackView.addArrangedSubview(startButton)
        
        if !isCreator {
            view.addSubview(blurView)
            view.addSubview(waitingLabel)
        }
        
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            containerStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            containerStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            containerStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            categoryPickerView.heightAnchor.constraint(equalToConstant: 150),
            startButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        if !isCreator {
            blurView.translatesAutoresizingMaskIntoConstraints = false
            waitingLabel.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                blurView.topAnchor.constraint(equalTo: view.topAnchor),
                blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                blurView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                
                waitingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                waitingLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                waitingLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
                waitingLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
            ])
        }
        
        // UI bileşenlerinin etkinliğini ayarla
        categoryPickerView.isUserInteractionEnabled = isCreator
        difficultySegmentedControl.isEnabled = isCreator
        startButton.isEnabled = isCreator
    }
    
    private func setupPickerView() {
        categoryPickerView.delegate = self
        categoryPickerView.dataSource = self
    }
    
    private func setupActions() {
        startButton.addTarget(self, action: #selector(startButtonTapped), for: .touchUpInside)
    }
    
    private func setupCloseButton() {
        let closeButton = UIBarButtonItem(image: UIImage(systemName: "xmark"),
                                        style: .plain,
                                        target: self,
                                        action: #selector(closeButtonTapped))
        closeButton.tintColor = .systemRed
        navigationItem.leftBarButtonItem = closeButton
    }
    
    private func fetchCategories() {
        FirebaseService.shared.getQuizCategories { [weak self] result in
            switch result {
            case .success(let categories):
                self?.categories = categories
                DispatchQueue.main.async {
                    self?.categoryPickerView.reloadAllComponents()
                }
            case .failure(let error):
                print("Error fetching categories: \(error)")
            }
        }
    }
    
    private func observeBattleStatus() {
        guard !battleId.isEmpty else {
            print("Error: Battle ID is empty")
            return
        }
        
        print("Observing battle status for battle ID: \(battleId)")
        
        // Önce mevcut battle'ın geçerli olup olmadığını kontrol et
        db.collection("battles").document(battleId).getDocument { [weak self] snapshot, error in
            if let error = error {
                print("Error checking battle status: \(error)")
                self?.navigationController?.popToRootViewController(animated: true)
                return
            }
            
            guard let data = snapshot?.data(),
                  let players = data["players"] as? [String],
                  let status = data["status"] as? String else {
                print("Invalid battle data or battle doesn't exist")
                self?.navigationController?.popToRootViewController(animated: true)
                return
            }
            
            // Eğer battle zaten başlamışsa veya iptal edilmişse ana sayfaya dön
            if status == "ended" || status == "cancelled" {
                self?.navigationController?.popToRootViewController(animated: true)
                return
            }
            
            // Battle'ı dinlemeye başla
            self?.db.collection("battles").document(self?.battleId ?? "")
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
                        if let category = data["category"] as? String,
                           let difficulty = data["difficulty"] as? String {
                            DispatchQueue.main.async {
                                let quizBattleVC = QuizBattleViewController(category: category,
                                                                          difficulty: difficulty,
                                                                          battleId: self?.battleId ?? "",
                                                                          opponentId: self?.opponentId ?? "")
                                self?.navigationController?.setViewControllers([quizBattleVC], animated: true)
                            }
                        }
                    } else if status == "cancelled" || status == "ended" {
                        DispatchQueue.main.async {
                            self?.navigationController?.popToRootViewController(animated: true)
                        }
                    }
                }
        }
    }
    
    @objc private func startButtonTapped() {
        guard let selectedCategory = categories[safe: categoryPickerView.selectedRow(inComponent: 0)] else { return }
        let difficulties = ["easy", "medium", "hard"]
        let selectedDifficulty = difficulties[difficultySegmentedControl.selectedSegmentIndex]
        
        // Butonu devre dışı bırak
        startButton.isEnabled = false
        
        // Önce battle'ın hala geçerli olduğunu kontrol et
        db.collection("battles").document(battleId).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error checking battle status: \(error)")
                self.startButton.isEnabled = true
                return
            }
            
            guard let data = snapshot?.data(),
                  let players = data["players"] as? [String],
                  let status = data["status"] as? String,
                  status != "started",
                  status != "ended",
                  status != "cancelled",
                  players.contains(self.opponentId) else {
                print("Battle is no longer valid")
                self.startButton.isEnabled = true
                self.navigationController?.popToRootViewController(animated: true)
                return
            }
            
            // Battle'ı başlat
            self.db.collection("battles").document(self.battleId).updateData([
                "status": "started",
                "category": selectedCategory,
                "difficulty": selectedDifficulty,
                "startedAt": Timestamp()
            ]) { error in
                if let error = error {
                    print("Error updating battle: \(error)")
                    self.startButton.isEnabled = true
                    return
                }
                
                DispatchQueue.main.async {
                    let quizBattleVC = QuizBattleViewController(category: selectedCategory,
                                                              difficulty: selectedDifficulty,
                                                              battleId: self.battleId,
                                                              opponentId: self.opponentId)
                    self.navigationController?.setViewControllers([quizBattleVC], animated: true)
                }
            }
        }
    }
    
    @objc private func closeButtonTapped() {
        let alert = UIAlertController(
            title: "Yarışmadan Çık",
            message: "Yarışmadan çıkmak istediğinize emin misiniz?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Hayır", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Evet", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            // Battle'ı iptal et
            self.db.collection("battles").document(self.battleId).updateData([
                "status": "cancelled",
                "cancelledAt": Timestamp(),
                "cancelledBy": Auth.auth().currentUser?.uid ?? ""
            ]) { error in
                if let error = error {
                    print("Error cancelling battle: \(error)")
                }
                
                // Battle invitation'ı sil
                self.db.collection("battleInvitations").document(self.battleId).delete()
                
                // Ana sayfaya dön
                self.navigationController?.popToRootViewController(animated: true)
            }
        })
        
        present(alert, animated: true)
    }
}

// MARK: - UIPickerView DataSource & Delegate
extension BattleInvitationViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return categories.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return categories[row]
    }
}

// Array extension for safe index access
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
} 