import UIKit
import Combine

class HomeViewController: UIViewController {
    private let viewModel = AuthViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    private let greetingLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .primaryPurple
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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
        ("Art", "🎨")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
        updateGreeting()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(greetingLabel)
        view.addSubview(aiCard)
        aiCard.addSubview(aiLabel)
        aiCard.addSubview(askAIButton)
        view.addSubview(categoriesLabel)
        view.addSubview(categoriesCollectionView)
        
        NSLayoutConstraint.activate([
            greetingLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            greetingLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            greetingLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
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
    }
    
    private func setupCollectionView() {
        categoriesCollectionView.delegate = self
        categoriesCollectionView.dataSource = self
        categoriesCollectionView.register(CategoryCell.self, forCellWithReuseIdentifier: "CategoryCell")
    }
    
    private func updateGreeting() {
        let hour = Calendar.current.component(.hour, from: Date())
        var greeting = ""
        
        switch hour {
        case 6..<12:
            greeting = "Good Morning"
        case 12..<17:
            greeting = "Good Afternoon"
        case 17..<22:
            greeting = "Good Evening"
        default:
            greeting = "Good Night"
        }
        
        if let user = viewModel.currentUser {
            greetingLabel.text = "\(greeting)\n\(user.name)"
        }
    }
    
    @objc private func askAIButtonTapped() {
        // TODO: Implement AI chat functionality
    }
}

extension HomeViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CategoryCell", for: indexPath) as! CategoryCell
        let category = categories[indexPath.item]
        cell.configure(title: category.title, icon: category.icon)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 16) / 2
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let category = categories[indexPath.item]
        let difficultyVC = DifficultyViewController(category: category.title)
        difficultyVC.modalPresentationStyle = .fullScreen
        present(difficultyVC, animated: true)
    }
}

class CategoryCell: UICollectionViewCell {
    private let iconLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 40)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .backgroundPurple
        layer.cornerRadius = 12
        
        contentView.addSubview(iconLabel)
        contentView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            iconLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -10),
            
            titleLabel.topAnchor.constraint(equalTo: iconLabel.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
        ])
    }
    
    func configure(title: String, icon: String) {
        titleLabel.text = title
        iconLabel.text = icon
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        addShadow()
    }
} 