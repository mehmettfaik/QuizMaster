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
    
    private let topGradientView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let greetingLabel: UILabel = { //Günaydın Kısmı
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = UIColor(red: 255/255, green: 215/255, blue: 0/255, alpha: 1) // Altın rengi (FFD700)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 30, weight: .bold)
        label.textColor = .white
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let friendsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "person.2.fill"), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let aiCard: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 1, alpha: 0.15)
        view.layer.cornerRadius = 20
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let aiTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "QuizGPT"
        label.font = .systemFont(ofSize: 24, weight: .bold) // Daha büyük ve çarpıcı font
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        // Gradient Text
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 255/255, green: 215/255, blue: 0/255, alpha: 1).cgColor, // Açık Mor
            UIColor(red: 0.58, green: 0.40, blue: 0.93, alpha: 1.0).cgColor  // Koyu Mor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.frame = CGRect(x: 0, y: 0, width: 300, height: 40)

        let textImage = UIGraphicsImageRenderer(size: gradientLayer.frame.size).image { context in
            gradientLayer.render(in: context.cgContext)
        }
        label.textColor = UIColor(patternImage: textImage) // Gradient rengi yazıya uygula

        // Hafif Gölge
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowOffset = CGSize(width: 2, height: 2)
        label.layer.shadowOpacity = 0.5
        label.layer.shadowRadius = 3

        return label
    }()

    
    private let aiDescriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Our artificial intelligence knows everything, you should still try your luck :)"
        label.numberOfLines = 3
        label.textColor = UIColor(white: 1.0, alpha: 0.85) // Beyaz ama çok hafif opak
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 18, weight: .medium) // Başlık ile uyumlu font
        label.translatesAutoresizingMaskIntoConstraints = false

        return label
    }()

    
    private let aiImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "ai_robot")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let askAIButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Ask AI", for: .normal)
        button.backgroundColor = .white
        button.setTitleColor(.primaryPurple, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = 20
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let categoriesLabel: UILabel = {
        let label = UILabel()
        label.text = "Quiz Categories"
        label.font = .systemFont(ofSize: 24, weight: .bold)
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
        ("History", "🏛️", 128),
        ("Art", "🎨", 30),
        ("Diğer", "⏩", 24)
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGradient()
        setupCollectionView()
        setupBindings()
        updateGreeting()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadUserProfile()
    }
    
    private func setupGradient() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 0.58, green: 0.40, blue: 0.93, alpha: 1.0).cgColor, // Açık Mor
            UIColor(red: 0.53, green: 0.35, blue: 0.91, alpha: 1.0).cgColor  // Koyu Mor
        ]
        gradientLayer.locations = [0.0, 1.0]
        
        let gradientHeight: CGFloat = 550
        let gradientYOffset: CGFloat = -100 // Mor kısmı yukarı taşımak için negatif değer veriyoruz
        gradientLayer.frame = CGRect(x: 0, y: gradientYOffset, width: view.bounds.width, height: gradientHeight)

        topGradientView.layer.insertSublayer(gradientLayer, at: 0)

        // Eğimin yukarı kaydırılması
        let curveHeight: CGFloat = 120
        let shapeLayer = CAShapeLayer()
        let path = UIBezierPath()

        // Başlangıç noktası (sol üst köşe)
        path.move(to: CGPoint(x: 0, y: gradientYOffset))
        // Sağ üst köşe
        path.addLine(to: CGPoint(x: view.bounds.width, y: gradientYOffset))
        // Sağ alt köşe (eğim başlangıcı)
        path.addLine(to: CGPoint(x: view.bounds.width, y: gradientHeight - curveHeight + gradientYOffset))
        // Eğimi yukarı kaydır
        path.addQuadCurve(to: CGPoint(x: 0, y: gradientHeight - curveHeight + gradientYOffset), controlPoint: CGPoint(x: view.bounds.width / 2, y: gradientHeight + gradientYOffset))
        // Sol alt köşe
        path.addLine(to: CGPoint(x: 0, y: gradientYOffset))

        shapeLayer.path = path.cgPath
        shapeLayer.fillColor = UIColor.white.cgColor
        topGradientView.layer.mask = shapeLayer
    }



    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(topGradientView)
        contentView.addSubview(greetingLabel)
        contentView.addSubview(nameLabel)
        contentView.addSubview(friendsButton)
        contentView.addSubview(aiCard)
        contentView.addSubview(categoriesLabel)
        contentView.addSubview(categoriesCollectionView)
        
        aiCard.addSubview(aiTitleLabel)
        aiCard.addSubview(aiDescriptionLabel)
        aiCard.addSubview(aiImageView)
        aiCard.addSubview(askAIButton)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            topGradientView.topAnchor.constraint(equalTo: contentView.topAnchor),
            topGradientView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            topGradientView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            topGradientView.heightAnchor.constraint(equalToConstant: 400),
            
            greetingLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 35),
            greetingLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            greetingLabel.trailingAnchor.constraint(equalTo: friendsButton.leadingAnchor, constant: -20),
            
            nameLabel.topAnchor.constraint(equalTo: greetingLabel.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            friendsButton.topAnchor.constraint(equalTo: greetingLabel.topAnchor),
            friendsButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            friendsButton.widthAnchor.constraint(equalToConstant: 44),
            friendsButton.heightAnchor.constraint(equalToConstant: 44),
            
            aiCard.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 24),
            aiCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            aiCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            aiCard.heightAnchor.constraint(equalToConstant: 160),
            
            aiTitleLabel.topAnchor.constraint(equalTo: aiCard.topAnchor, constant: 20),
            aiTitleLabel.leadingAnchor.constraint(equalTo: aiCard.leadingAnchor, constant: 20),
            
            aiDescriptionLabel.topAnchor.constraint(equalTo: aiTitleLabel.bottomAnchor, constant: 12),
            aiDescriptionLabel.leadingAnchor.constraint(equalTo: aiCard.leadingAnchor, constant: 20),
            aiDescriptionLabel.trailingAnchor.constraint(equalTo: aiImageView.leadingAnchor, constant: -12),
            
            aiImageView.centerYAnchor.constraint(equalTo: aiCard.centerYAnchor),
            aiImageView.trailingAnchor.constraint(equalTo: aiCard.trailingAnchor, constant: -20),
            aiImageView.widthAnchor.constraint(equalToConstant: 80),
            aiImageView.heightAnchor.constraint(equalToConstant: 80),
            
            askAIButton.topAnchor.constraint(equalTo: aiDescriptionLabel.bottomAnchor, constant: 16),
            askAIButton.leadingAnchor.constraint(equalTo: aiCard.leadingAnchor, constant: 20),
            askAIButton.heightAnchor.constraint(equalToConstant: 40),
            askAIButton.widthAnchor.constraint(equalToConstant: 120),
            
            categoriesLabel.topAnchor.constraint(equalTo: topGradientView.bottomAnchor, constant: 30),
            categoriesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            categoriesCollectionView.topAnchor.constraint(equalTo: categoriesLabel.bottomAnchor, constant: 20),
            categoriesCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            categoriesCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            categoriesCollectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            categoriesCollectionView.heightAnchor.constraint(equalToConstant: 700)
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
            greeting = "GOOD MORNING ☀️"
        case 12..<17:
            greeting = "GOOD AFTERNOON ⛅️ "
        case 17..<22:
            greeting = "GOOD EVENING 🌅"
        default:
            greeting = "GOOD NIGHT 🌙"
        }
        
        greetingLabel.text = greeting
        if !name.isEmpty {
            nameLabel.text = name
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
            if let cell = collectionView.cellForItem(at: indexPath) as? CategoryCell {
                cell.triggerShakeAnimation()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    // Dismiss current view controller to return to TabBarController
                    self.dismiss(animated: true) { [weak self] in
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
                } else if category.title == "Sports" {
                    cell.triggerSportsAnimation()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                        let difficultyVC = DifficultyViewController(category: category.title)
                        difficultyVC.modalPresentationStyle = .fullScreen
                        self.present(difficultyVC, animated: true)
                    }
                } else if category.title == "Art" {
                    cell.triggerArtAnimation()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                        let difficultyVC = DifficultyViewController(category: category.title)
                        difficultyVC.modalPresentationStyle = .fullScreen
                        self.present(difficultyVC, animated: true)
                    }
                } else if category.title == "Science" {
                    cell.triggerScienceAnimation()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        let difficultyVC = DifficultyViewController(category: category.title)
                        difficultyVC.modalPresentationStyle = .fullScreen
                        self.present(difficultyVC, animated: true)
                    }
                } else if category.title == "History" {
                    cell.triggerHistoryAnimation()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
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
