import UIKit
import Combine

// MARK: - UIViewController Extension
extension UIViewController {
    func showErrorAlert(_ error: Error) {
        let alert = UIAlertController(
            title: "Hata",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
        present(alert, animated: true)
    }
}

class ProfileViewController: UIViewController {
    private let viewModel = UserViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .backgroundPurple
        imageView.layer.cornerRadius = 50
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .black
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = true
        return label
    }()
    
    private let editNameButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "pencil.circle.fill"), for: .normal)
        button.tintColor = .primaryPurple
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let emailLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .gray
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let achievementsLabel: UILabel = {
        let label = UILabel()
        label.text = "Başarı Rozetleri"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let achievementsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 16
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .primaryPurple
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private let signOutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Çıkış Yap", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemRed
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
        setupBindings()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadUserProfile()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(profileImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(editNameButton)
        contentView.addSubview(emailLabel)
        contentView.addSubview(achievementsLabel)
        contentView.addSubview(achievementsCollectionView)
        contentView.addSubview(signOutButton)
        contentView.addSubview(loadingIndicator)
        
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
            
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            profileImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 100),
            profileImageView.heightAnchor.constraint(equalToConstant: 100),
            
            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            editNameButton.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: -40),
            editNameButton.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            editNameButton.widthAnchor.constraint(equalToConstant: 30),
            editNameButton.heightAnchor.constraint(equalToConstant: 30),
            
            emailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            emailLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            emailLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            achievementsLabel.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 32),
            achievementsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            achievementsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            achievementsCollectionView.topAnchor.constraint(equalTo: achievementsLabel.bottomAnchor, constant: 16),
            achievementsCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            achievementsCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            achievementsCollectionView.heightAnchor.constraint(equalToConstant: 500),
            
            signOutButton.topAnchor.constraint(equalTo: achievementsCollectionView.bottomAnchor, constant: 20),
            signOutButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            signOutButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            signOutButton.heightAnchor.constraint(equalToConstant: 50),
            signOutButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        
        // Profil fotoğrafı için placeholder
        profileImageView.image = UIImage(systemName: "person.circle.fill")
        profileImageView.tintColor = .primaryPurple
        
        // Sign Out action
        signOutButton.addTarget(self, action: #selector(signOutTapped), for: .touchUpInside)
        
        // Edit name action
        editNameButton.addTarget(self, action: #selector(editNameTapped), for: .touchUpInside)
        
        // Add tap gesture to name label
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(editNameTapped))
        nameLabel.addGestureRecognizer(tapGesture)
    }
    
    private func setupCollectionView() {
        achievementsCollectionView.delegate = self
        achievementsCollectionView.dataSource = self
        achievementsCollectionView.register(AchievementCell.self, forCellWithReuseIdentifier: "AchievementCell")
    }
    
    private func setupBindings() {
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.loadingIndicator.startAnimating()
                } else {
                    self?.loadingIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)
        
        viewModel.$userName
            .receive(on: DispatchQueue.main)
            .sink { [weak self] name in
                self?.nameLabel.text = name
            }
            .store(in: &cancellables)
        
        viewModel.$userEmail
            .receive(on: DispatchQueue.main)
            .sink { [weak self] email in
                self?.emailLabel.text = email
            }
            .store(in: &cancellables)
        
        viewModel.$achievements
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.achievementsCollectionView.reloadData()
            }
            .store(in: &cancellables)
            
        viewModel.$error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                if let error = error {
                    self?.showErrorAlert(error)
                }
            }
            .store(in: &cancellables)
    }
    
    @objc private func signOutTapped() {
        let alert = UIAlertController(
            title: "Çıkış Yap",
            message: "Çıkış yapmak istediğinize emin misiniz?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel))
        alert.addAction(UIAlertAction(title: "Çıkış Yap", style: .destructive) { [weak self] _ in
            self?.viewModel.signOut()
            let loginVC = LoginViewController()
            loginVC.modalPresentationStyle = .fullScreen
            self?.present(loginVC, animated: true)
        })
        
        present(alert, animated: true)
    }
    
    @objc private func editNameTapped() {
        let alert = UIAlertController(
            title: "İsim Değiştir",
            message: "Yeni isminizi girin",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.text = self.nameLabel.text
            textField.placeholder = "İsminiz"
            textField.autocapitalizationType = .words
        }
        
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel))
        alert.addAction(UIAlertAction(title: "Kaydet", style: .default) { [weak self] _ in
            guard let self = self,
                  let textField = alert.textFields?.first,
                  let newName = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !newName.isEmpty else { return }
            
            // Show loading indicator
            self.loadingIndicator.startAnimating()
            
            // Update name in Firebase
            self.viewModel.updateUserName(newName) { [weak self] error in
                DispatchQueue.main.async {
                    self?.loadingIndicator.stopAnimating()
                    
                    if let error = error {
                        self?.showErrorAlert(error)
                    }
                }
            }
        })
        
        present(alert, animated: true)
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension ProfileViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if viewModel.achievements.isEmpty {
            return 1 // Eğer rozet yoksa bir hücre göster
        }
        return viewModel.achievements.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AchievementCell", for: indexPath) as! AchievementCell
        
        if viewModel.achievements.isEmpty {
            // Eğer rozet yoksa bilgilendirme mesajı göster
            cell.configureAsPlaceholder()
        } else {
            let achievement = viewModel.achievements[indexPath.item]
            cell.configure(with: achievement)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 16) / 2
        return CGSize(width: width, height: 120)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let achievement = viewModel.achievements[indexPath.item]
        
        let alert = UIAlertController(
            title: achievement.title,
            message: "\(achievement.description)\n\nİlerleme: \(achievement.currentValue)/\(achievement.requirement)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Achievement Cell
class AchievementCell: UICollectionViewCell {
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .backgroundPurple
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .black
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .gray
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.trackTintColor = .systemGray5
        progress.progressTintColor = .primaryPurple
        progress.translatesAutoresizingMaskIntoConstraints = false
        return progress
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(iconImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(progressView)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            iconImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            iconImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 40),
            iconImageView.heightAnchor.constraint(equalToConstant: 40),
            
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            
            progressView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 8),
            progressView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            progressView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            progressView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
    }
    
    func configure(with achievement: AchievementBadge) {
        titleLabel.text = achievement.title
        descriptionLabel.text = achievement.description
        iconImageView.image = UIImage(systemName: achievement.icon)
        iconImageView.tintColor = achievement.isUnlocked ? .primaryPurple : .gray
        progressView.progress = Float(achievement.progress)
        
        // Kilitsiz/kilitli duruma göre opacity ayarla
        containerView.alpha = achievement.isUnlocked ? 1.0 : 0.7
    }
    
    func configureAsPlaceholder() {
        titleLabel.text = "Henüz Rozet Yok"
        descriptionLabel.text = "Quiz çözerek rozetler kazanabilirsiniz!"
        iconImageView.image = UIImage(systemName: "star.circle")
        iconImageView.tintColor = .gray
        progressView.isHidden = true
        containerView.alpha = 0.7
    }
} 