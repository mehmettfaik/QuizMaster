import UIKit
import Combine

class HomeViewController: UIViewController {
    private let viewModel = UserViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    private let greetingLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .primaryPurple
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let friendsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "person.2.fill"), for: .normal)
        button.tintColor = .primaryPurple
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let aiCard: UIView = {
        let view = UIView()
        view.backgroundColor = .secondaryPurple
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let aiLabel: UILabel = {
        let label = UILabel()
        label.text = "Yapay zeka ismi\n\nOur artificial intelligence knows everything, you should still try your luck :)"
        label.numberOfLines = 0
        label.textColor = .white
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let askAIButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Ask AI", for: .normal)
        button.backgroundColor = .white
        button.setTitleColor(.primaryPurple, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let categoriesLabel: UILabel = {
        let label = UILabel()
        label.text = "Quiz Categories"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let categoriesCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 16
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    private let categories: [(title: String, icon: String)] = [
        ("Vehicle", "🚗"),
        ("Science", "🔬"),
        ("Sports", "⚽️"),
        ("History", "📚"),
        ("Art", "🎨"),
        ("Diğer", "⏩")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
        setupBindings()
        updateGreeting()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadUserProfile()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(greetingLabel)
        view.addSubview(friendsButton)
        view.addSubview(aiCard)
        aiCard.addSubview(aiLabel)
        aiCard.addSubview(askAIButton)
        view.addSubview(categoriesLabel)
        view.addSubview(categoriesCollectionView)
        
        NSLayoutConstraint.activate([
            greetingLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            greetingLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            greetingLabel.trailingAnchor.constraint(equalTo: friendsButton.leadingAnchor, constant: -8),
            
            friendsButton.centerYAnchor.constraint(equalTo: greetingLabel.centerYAnchor),
            friendsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            friendsButton.widthAnchor.constraint(equalToConstant: 44),
            friendsButton.heightAnchor.constraint(equalToConstant: 44),
            
            aiCard.topAnchor.constraint(equalTo: greetingLabel.bottomAnchor, constant: 20),
            aiCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            aiCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            aiCard.heightAnchor.constraint(equalToConstant: 150),
            
            aiLabel.topAnchor.constraint(equalTo: aiCard.topAnchor, constant: 16),
            aiLabel.leadingAnchor.constraint(equalTo: aiCard.leadingAnchor, constant: 16),
            aiLabel.trailingAnchor.constraint(equalTo: aiCard.trailingAnchor, constant: -16),
            
            askAIButton.bottomAnchor.constraint(equalTo: aiCard.bottomAnchor, constant: -16),
            askAIButton.leadingAnchor.constraint(equalTo: aiCard.leadingAnchor, constant: 16),
            askAIButton.heightAnchor.constraint(equalToConstant: 40),
            askAIButton.widthAnchor.constraint(equalToConstant: 100),
            
            categoriesLabel.topAnchor.constraint(equalTo: aiCard.bottomAnchor, constant: 30),
            categoriesLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            categoriesCollectionView.topAnchor.constraint(equalTo: categoriesLabel.bottomAnchor, constant: 20),
            categoriesCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            categoriesCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            categoriesCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        askAIButton.addTarget(self, action: #selector(askAIButtonTapped), for: .touchUpInside)
        friendsButton.addTarget(self, action: #selector(friendsButtonTapped), for: .touchUpInside)
    }
    
    private func setupCollectionView() {
        categoriesCollectionView.delegate = self
        categoriesCollectionView.dataSource = self
        categoriesCollectionView.register(CategoryCell.self, forCellWithReuseIdentifier: "CategoryCell")
    }
    
    private func setupBindings() {
        viewModel.$userName
            .receive(on: DispatchQueue.main)
            .sink { [weak self] name in
                self?.updateGreeting(with: name)
            }
            .store(in: &cancellables)
    }
    
    private func updateGreeting(with name: String = "") {
        let hour = Calendar.current.component(.hour, from: Date())
        var greeting = ""
        
        switch hour {
        case 6..<12:
            greeting = "Günaydın"
        case 12..<17:
            greeting = "İyi Günler"
        case 17..<22:
            greeting = "İyi Akşamlar"
        default:
            greeting = "İyi Geceler"
        }
        
        if !name.isEmpty {
            greetingLabel.text = "\(greeting),\n\(name)"
        } else {
            greetingLabel.text = greeting
        }
    }
    
    @objc private func askAIButtonTapped() {
        let chatVC = ChatViewController()
        chatVC.modalPresentationStyle = .overFullScreen
        present(chatVC, animated: true)
    }
    
    @objc private func friendsButtonTapped() {
        let friendsVC = FriendsViewController()
        let nav = UINavigationController(rootViewController: friendsVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
}

extension HomeViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CategoryCell", for: indexPath) as! CategoryCell
        let category = categories[indexPath.item]
        cell.configure(title: category.title, icon: category.icon, style: .classic)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
       // let spacing: CGFloat = 16
        let width = (collectionView.bounds.width - 16 ) / 2 // 32 is the total horizontal padding
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let category = categories[indexPath.item]
        
        if category.title == "Diğer" {
            // Dismiss current view controller to return to TabBarController
            dismiss(animated: true) { [weak self] in
                // Get reference to TabBarController and switch to Search tab (assuming it's index 1)
                if let tabBarController = UIApplication.shared.windows.first?.rootViewController as? UITabBarController {
                    tabBarController.selectedIndex = 1
                    // Get reference to SearchViewController and update its state
                    if let searchVC = tabBarController.selectedViewController as? SearchViewController {
                        searchVC.segmentedControl.selectedSegmentIndex = 0
                        searchVC.segmentedControlValueChanged()
                    }
                }
            }
        } else {
            let difficultyVC = DifficultyViewController(category: category.title)
            difficultyVC.modalPresentationStyle = .fullScreen
            present(difficultyVC, animated: true)
        }
    }
} 
