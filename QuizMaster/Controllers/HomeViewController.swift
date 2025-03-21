import UIKit
import Combine

class HomeViewController: UIViewController {
    private let viewModel = UserViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
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
        view.layer.cornerRadius = 20
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 12
        view.layer.shadowOpacity = 0.1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let aiIconImageView: UIImageView = {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)
        imageView.image = UIImage(systemName: "sparkles.square.filled.on.square", withConfiguration: config)
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let aiNameLabel: UILabel = {
        let label = UILabel()
        label.text = "QuizGPT"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let aiDescriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Your AI quiz companion. Get instant help \nand explore new topics! ✨"
        label.numberOfLines = 4
        label.textColor = UIColor.white.withAlphaComponent(0.9)
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let askAIButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Ask AI", for: .normal)
        button.backgroundColor = .white
        button.setTitleColor(.primaryPurple, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = 20
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.1
        
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let image = UIImage(systemName: "arrow.forward", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .primaryPurple
        button.semanticContentAttribute = .forceRightToLeft
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: -8)
        
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
        collectionView.showsVerticalScrollIndicator = false
        collectionView.isScrollEnabled = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    private let categories: [(title: String, icon: String, questions: Int)] = [
        ("Vehicle", "🚗", 50),
        ("Science", "🔬", 30),
        ("Sports", "⚽️", 95),
        ("History", "📚", 128),
        ("Art", "🎨", 30),
        ("Diğer", "⏩", 24)
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
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(greetingLabel)
        contentView.addSubview(friendsButton)
        contentView.addSubview(aiCard)
        contentView.addSubview(categoriesLabel)
        contentView.addSubview(categoriesCollectionView)
        
        aiCard.addSubview(aiIconImageView)
        aiCard.addSubview(aiNameLabel)
        aiCard.addSubview(aiDescriptionLabel)
        aiCard.addSubview(askAIButton)
        
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
            
            greetingLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            greetingLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            greetingLabel.trailingAnchor.constraint(equalTo: friendsButton.leadingAnchor, constant: -8),
            
            friendsButton.centerYAnchor.constraint(equalTo: greetingLabel.centerYAnchor),
            friendsButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            friendsButton.widthAnchor.constraint(equalToConstant: 44),
            friendsButton.heightAnchor.constraint(equalToConstant: 44),
            
            aiCard.topAnchor.constraint(equalTo: greetingLabel.bottomAnchor, constant: 20),
            aiCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            aiCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            aiCard.heightAnchor.constraint(equalToConstant: 200),
            
            aiIconImageView.topAnchor.constraint(equalTo: aiCard.topAnchor, constant: 24),
            aiIconImageView.leadingAnchor.constraint(equalTo: aiCard.leadingAnchor, constant: 24),
            aiIconImageView.widthAnchor.constraint(equalToConstant: 36),
            aiIconImageView.heightAnchor.constraint(equalToConstant: 36),
            
            aiNameLabel.leadingAnchor.constraint(equalTo: aiIconImageView.trailingAnchor, constant: 12),
            aiNameLabel.centerYAnchor.constraint(equalTo: aiIconImageView.centerYAnchor),
            
            aiDescriptionLabel.topAnchor.constraint(equalTo: aiIconImageView.bottomAnchor, constant: 16),
            aiDescriptionLabel.leadingAnchor.constraint(equalTo: aiCard.leadingAnchor, constant: 24),
            aiDescriptionLabel.trailingAnchor.constraint(equalTo: aiCard.trailingAnchor, constant: -24),
            
            askAIButton.topAnchor.constraint(equalTo: aiDescriptionLabel.bottomAnchor, constant: 16),
            askAIButton.leadingAnchor.constraint(equalTo: aiCard.leadingAnchor, constant: 24),
            askAIButton.heightAnchor.constraint(equalToConstant: 40),
            askAIButton.widthAnchor.constraint(equalToConstant: 140),
            askAIButton.bottomAnchor.constraint(equalTo: aiCard.bottomAnchor, constant: -24),
            
            categoriesLabel.topAnchor.constraint(equalTo: aiCard.bottomAnchor, constant: 30),
            categoriesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            categoriesCollectionView.topAnchor.constraint(equalTo: categoriesLabel.bottomAnchor, constant: 20),
            categoriesCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            categoriesCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            categoriesCollectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            categoriesCollectionView.heightAnchor.constraint(equalToConstant: 600)
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
        cell.configure(title: category.title, icon: category.icon, style: .classic, questionCount: category.questions)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 16) / 2
        return CGSize(width: width, height: width * 1.2)
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
            if let cell = collectionView.cellForItem(at: indexPath) as? CategoryCell {
                if category.title == "Vehicle" {
                    cell.animateIconExit()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        let difficultyVC = DifficultyViewController(category: category.title)
                        difficultyVC.modalPresentationStyle = .fullScreen
                        self.present(difficultyVC, animated: true)
                    }
                } else {
                    let difficultyVC = DifficultyViewController(category: category.title)
                    difficultyVC.modalPresentationStyle = .fullScreen
                    present(difficultyVC, animated: true)
                }
            }
        }
    }
} 
