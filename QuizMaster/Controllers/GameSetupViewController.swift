import UIKit
import FirebaseFirestore

class GameSetupViewController: UIViewController {
    private let game: MultiplayerGame
    private let multiplayerService = MultiplayerGameService.shared
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Oyun Ayarları"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 20
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 10
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let categoryLabel: UILabel = {
        let label = UILabel()
        label.text = "Kategori Seçin"
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .primaryPurple
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let difficultyLabel: UILabel = {
        let label = UILabel()
        label.text = "Zorluk Seçin"
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .primaryPurple
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let categoryPicker: UIPickerView = {
        let picker = UIPickerView()
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()
    
    private let difficultyPicker: UIPickerView = {
        let picker = UIPickerView()
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()
    
    private let startButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Oyunu Başlat", for: .normal)
        button.backgroundColor = .primaryPurple
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .primaryPurple
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private var categories: [QuizCategory] = []
    private let difficulties = ["Easy", "Medium", "Hard"]
    
    // Listeners
    private var categoryListener: ListenerRegistration?
    private var gameListener: ListenerRegistration?
    
    init(game: MultiplayerGame) {
        self.game = game
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWave()
        setupUI()
        setupListeners()
        fetchCategories()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        categoryListener?.remove()
        gameListener?.remove()
    }
    
    private func setupWave() {
        let purpleView = UIView()
        purpleView.backgroundColor = .primaryPurple
        purpleView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(purpleView)
        
        NSLayoutConstraint.activate([
            purpleView.topAnchor.constraint(equalTo: view.topAnchor),
            purpleView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            purpleView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            purpleView.heightAnchor.constraint(equalToConstant: 120)
        ])
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        navigationItem.title = ""
        
        view.addSubview(titleLabel)
        view.addSubview(containerView)
        view.addSubview(loadingIndicator)
        
        containerView.addSubview(categoryLabel)
        containerView.addSubview(categoryPicker)
        containerView.addSubview(difficultyLabel)
        containerView.addSubview(difficultyPicker)
        containerView.addSubview(startButton)
        
        categoryPicker.delegate = self
        categoryPicker.dataSource = self
        difficultyPicker.delegate = self
        difficultyPicker.dataSource = self
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -35),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            containerView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            categoryLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            categoryLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            
            categoryPicker.topAnchor.constraint(equalTo: categoryLabel.bottomAnchor, constant: 10),
            categoryPicker.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            categoryPicker.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            categoryPicker.heightAnchor.constraint(equalToConstant: 150),
            
            difficultyLabel.topAnchor.constraint(equalTo: categoryPicker.bottomAnchor, constant: 20),
            difficultyLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            
            difficultyPicker.topAnchor.constraint(equalTo: difficultyLabel.bottomAnchor, constant: 10),
            difficultyPicker.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            difficultyPicker.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            difficultyPicker.heightAnchor.constraint(equalToConstant: 150),
            
            startButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -30),
            startButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            startButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            startButton.heightAnchor.constraint(equalToConstant: 50),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        startButton.addTarget(self, action: #selector(startButtonTapped), for: .touchUpInside)
    }
    
    private func setupListeners() {
        // Listen for game status changes
        gameListener = multiplayerService.listenForGameUpdates(gameId: game.id) { [weak self] result in
            switch result {
            case .success(let updatedGame):
                if updatedGame.status == .inProgress {
                    DispatchQueue.main.async {
                        let gameVC = MultiplayerGameViewController(game: updatedGame)
                        self?.navigationController?.pushViewController(gameVC, animated: true)
                    }
                }
            case .failure(let error):
                print("Error listening for game updates: \(error.localizedDescription)")
            }
        }
    }
    
    private func fetchCategories() {
        loadingIndicator.startAnimating()
        startButton.isEnabled = false
        
        categoryListener = multiplayerService.getQuizCategories { [weak self] result in
            DispatchQueue.main.async {
                self?.loadingIndicator.stopAnimating()
                self?.startButton.isEnabled = true
                
                switch result {
                case .success(let categories):
                    self?.categories = categories
                    self?.categoryPicker.reloadAllComponents()
                case .failure(let error):
                    self?.showAlert(title: "Error", message: "Failed to load categories: \(error.localizedDescription)")
                }
            }
        }
    }
    
    @objc private func startButtonTapped() {
        guard !categories.isEmpty else {
            showAlert(title: "Error", message: "Please wait for categories to load")
            return
        }
        
        let selectedCategory = categories[categoryPicker.selectedRow(inComponent: 0)]
        let selectedDifficulty = difficulties[difficultyPicker.selectedRow(inComponent: 0)].lowercased()
        
        startButton.isEnabled = false
        loadingIndicator.startAnimating()
        
        multiplayerService.setupGame(
            gameId: game.id,
            category: selectedCategory.rawValue,
            difficulty: selectedDifficulty
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.startButton.isEnabled = true
                self?.loadingIndicator.stopAnimating()
                
                switch result {
                case .success(let game):
                    print("Game setup successful: \(game.id)")
                case .failure(let error):
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension GameSetupViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerView == categoryPicker ? categories.count : difficulties.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerView == categoryPicker ? categories[row].rawValue : difficulties[row]
    }
} 