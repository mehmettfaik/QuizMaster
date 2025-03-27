import UIKit
import Combine
import FirebaseFirestore

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

// MARK: - Avatar Type
enum Avatar: String, CaseIterable {
    case leo = "leo"
    case alex = "alex"
    case owen = "owen"
    case mia = "mia"
    case sophia = "sophia"
    case olivia = "olivia"
    
    var image: UIImage? {
        // Her avatar için özel resim
        switch self {
        case .leo:
            return UIImage(named: "leo") ?? UIImage(systemName: systemImage)
        case .alex:
            return UIImage(named: "alex") ?? UIImage(systemName: systemImage)
        case .owen:
            return UIImage(named: "owen") ?? UIImage(systemName: systemImage)
        case .mia:
            return UIImage(named: "mia") ?? UIImage(systemName: systemImage)
        case .sophia:
            return UIImage(named: "sophia") ?? UIImage(systemName: systemImage)
        case .olivia:
            return UIImage(named: "olivia") ?? UIImage(systemName: systemImage)
        }
    }
    
    // Fallback için SF Symbols (eğer özel resim yüklenemezse)
    var systemImage: String {
        switch self {
        case .leo: return "person.fill.viewfinder"
        case .alex: return "person.fill.checkmark"
        case .owen: return "person.fill.questionmark"
        case .mia: return "person.fill.badge.plus"
        case .sophia: return "person.fill.turn.right"
        case .olivia: return "person.fill.magnifyingglass"
        }
    }
    
    var displayName: String {
        switch self {
        case .leo: return "Leo"
        case .alex: return "Alex"
        case .owen: return "Owen"
        case .mia: return "Mia"
        case .sophia: return "Sophia"
        case .olivia: return "Olivia"
        }
    }
    
    var color: UIColor {
        switch self {
        case .leo: return .white
        case .alex: return .white
        case .owen: return .white
        case .mia: return .white
        case .sophia: return .white
        case .olivia: return .white
        }
    }
    
    // Avatar arkaplan renkleri
    var backgroundColor: UIColor {
        switch self {
        case .leo: return .systemPurple.withAlphaComponent(0.1)
        case .alex: return .systemGray.withAlphaComponent(0.1)
        case .owen: return .systemBlue.withAlphaComponent(0.1)
        case .mia: return .systemRed.withAlphaComponent(0.1)
        case .sophia: return .systemOrange.withAlphaComponent(0.1)
        case .olivia: return .systemBrown.withAlphaComponent(0.1)
        }
    }
}

class ProfileViewController: UIViewController {
    private let viewModel = UserViewModel()
    private var cancellables = Set<AnyCancellable>()
    private let db = Firestore.firestore()
    
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
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.backgroundColor = .clear
        imageView.layer.cornerRadius = 70
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 4
        imageView.layer.borderColor = UIColor.primaryPurple.cgColor
        imageView.layer.shadowColor = UIColor.primaryPurple.cgColor
        imageView.layer.shadowOffset = CGSize(width: 0, height: 4)
        imageView.layer.shadowOpacity = 0.3
        imageView.layer.shadowRadius = 8
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textColor = .primaryPurple
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let emailLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .systemGray
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let achievementsLabel: UILabel = {
        let label = UILabel()
        label.text = "Başarı Rozetleri"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .primaryPurple
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
        collectionView.isScrollEnabled = false
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
    
    private let settingsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "gearshape.fill"), for: .normal)
        button.tintColor = .primaryPurple
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 44).isActive = true
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return button
    }()
    
    private let friendsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Arkadaşlarım", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .primaryPurple
        button.layer.cornerRadius = 20
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.layer.shadowColor = UIColor.primaryPurple.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowOpacity = 0.3
        button.layer.shadowRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = false
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.title = "Profil"
        setupUI()
        setupCollectionView()
        setupBindings()
        setupNavigationBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadUserProfile()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Gradient background for the top section
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.primaryPurple.withAlphaComponent(0.5).cgColor,
            UIColor.systemBackground.cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 300)
        view.layer.insertSublayer(gradientLayer, at: 0)
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(profileImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(emailLabel)
        contentView.addSubview(friendsButton)
        contentView.addSubview(achievementsLabel)
        contentView.addSubview(achievementsCollectionView)
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
            
            profileImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            profileImageView.widthAnchor.constraint(equalToConstant: 160),
            profileImageView.heightAnchor.constraint(equalToConstant: 160),
            
            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 24),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            emailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            emailLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            emailLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            friendsButton.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 40),
            friendsButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30),
            friendsButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30),
            friendsButton.heightAnchor.constraint(equalToConstant: 60),
            
            achievementsLabel.topAnchor.constraint(equalTo: friendsButton.bottomAnchor, constant: 50),
            achievementsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            achievementsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            achievementsCollectionView.topAnchor.constraint(equalTo: achievementsLabel.bottomAnchor, constant: 24),
            achievementsCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            achievementsCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            achievementsCollectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        
        // Profil fotoğrafı için placeholder
        profileImageView.image = UIImage(systemName: "person.circle.fill")
        profileImageView.tintColor = .primaryPurple
        profileImageView.backgroundColor = .systemGray6
        
        // Add action to friends button
        friendsButton.addTarget(self, action: #selector(friendsButtonTapped), for: .touchUpInside)
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
        
        viewModel.$userAvatar
            .receive(on: DispatchQueue.main)
            .sink { [weak self] avatarType in
                if let avatar = Avatar(rawValue: avatarType ?? "leo") {
                    self?.profileImageView.image = avatar.image
                    self?.profileImageView.backgroundColor = avatar.backgroundColor
                    
                    // Avatar görünüm ayarları
                    UIView.animate(withDuration: 0.3) {
                        self?.profileImageView.layer.borderColor = avatar.backgroundColor.cgColor
                        self?.profileImageView.layer.borderWidth = 2
                    }
                }
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
    
    private func setupNavigationBar() {
        let settingsBarButton = UIBarButtonItem(customView: settingsButton)
        navigationItem.rightBarButtonItem = settingsBarButton
        
        settingsButton.addTarget(self, action: #selector(settingsTapped), for: .touchUpInside)
    }
    
    @objc private func settingsTapped() {
        let settingsVC = SettingsViewController(viewModel: viewModel)
        let navController = UINavigationController(rootViewController: settingsVC)
        present(navController, animated: true)
    }
    
    @objc private func friendsButtonTapped() {
        let friendsListVC = FriendsListViewController(userId: viewModel.currentUserId ?? "")
        let nav = UINavigationController(rootViewController: friendsListVC)
        
        if #available(iOS 15.0, *) {
            if let sheet = nav.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 20
            }
        }
        
        present(nav, animated: true)
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension ProfileViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if viewModel.achievements.isEmpty {
            return 1
        }
        return viewModel.achievements.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AchievementCell", for: indexPath) as! AchievementCell
        
        if viewModel.achievements.isEmpty {
            cell.configureAsPlaceholder()
        } else {
            let achievement = viewModel.achievements[indexPath.item]
            cell.configure(with: achievement)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 32) / 2
        return CGSize(width: width, height: 180)
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacing: CGFloat) -> CGFloat {
        return 16
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacing: CGFloat) -> CGFloat {
        return 16
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Collection view'ın yüksekliğini içeriğine göre ayarla
        let numberOfItems = viewModel.achievements.isEmpty ? 1 : viewModel.achievements.count
        let numberOfRows = ceil(Double(numberOfItems) / 2.0)
        let itemHeight: CGFloat = 185
        let spacing: CGFloat = 16
        let totalHeight = (itemHeight * CGFloat(numberOfRows)) + (spacing * CGFloat(numberOfRows - 1))
        
        // Mevcut height constraint'i kaldır
        achievementsCollectionView.constraints.forEach { constraint in
            if constraint.firstAttribute == .height {
                achievementsCollectionView.removeConstraint(constraint)
            }
        }
        
        // Yeni height constraint ekle
        achievementsCollectionView.heightAnchor.constraint(equalToConstant: totalHeight).isActive = true
    }
}

// MARK: - Achievement Cell
class AchievementCell: UICollectionViewCell {
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 24
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowOpacity = 0.1
        view.layer.shadowRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let iconContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .primaryPurple.withAlphaComponent(0.1)
        view.layer.cornerRadius = 20
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
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .primaryPurple
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let progressContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.trackTintColor = .clear
        progress.progressTintColor = .primaryPurple
        progress.layer.cornerRadius = 8
        progress.clipsToBounds = true
        progress.translatesAutoresizingMaskIntoConstraints = false
        return progress
    }()
    
    private let progressLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .primaryPurple
        label.textAlignment = .center
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
        contentView.addSubview(containerView)
        containerView.addSubview(iconContainerView)
        iconContainerView.addSubview(iconImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(progressContainerView)
        progressContainerView.addSubview(progressView)
        containerView.addSubview(progressLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            iconContainerView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            iconContainerView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            iconContainerView.widthAnchor.constraint(equalToConstant: 48),
            iconContainerView.heightAnchor.constraint(equalToConstant: 48),
            
            iconImageView.centerXAnchor.constraint(equalTo: iconContainerView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.topAnchor.constraint(equalTo: iconContainerView.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            
            progressContainerView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 12),
            progressContainerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            progressContainerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            progressContainerView.heightAnchor.constraint(equalToConstant: 8),
            
            progressView.topAnchor.constraint(equalTo: progressContainerView.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: progressContainerView.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: progressContainerView.trailingAnchor),
            progressView.bottomAnchor.constraint(equalTo: progressContainerView.bottomAnchor),
            
            progressLabel.topAnchor.constraint(equalTo: progressContainerView.bottomAnchor, constant: 4),
            progressLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            progressLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with achievement: AchievementBadge) {
        titleLabel.text = achievement.title
        descriptionLabel.text = achievement.description
        iconImageView.image = UIImage(systemName: achievement.icon)
        iconImageView.tintColor = achievement.isUnlocked ? .primaryPurple : .gray
        progressView.progress = Float(achievement.progress)
        progressLabel.text = "\(achievement.currentValue)/\(achievement.requirement)"
        
        // Kilitsiz/kilitli duruma göre opacity ayarla
        containerView.alpha = achievement.isUnlocked ? 1.0 : 0.7
        iconContainerView.backgroundColor = achievement.isUnlocked ? .primaryPurple.withAlphaComponent(0.1) : .systemGray5
    }
    
    func configureAsPlaceholder() {
        titleLabel.text = "Henüz Rozet Yok"
        descriptionLabel.text = "Quiz çözerek rozetler kazanabilirsiniz!"
        iconImageView.image = UIImage(systemName: "star.circle")
        iconImageView.tintColor = .gray
        progressView.isHidden = true
        progressLabel.isHidden = true
        containerView.alpha = 0.7
        iconContainerView.backgroundColor = .systemGray5
    }
}

// MARK: - Settings View Controller
class SettingsViewController: UIViewController {
    private let viewModel: UserViewModel
    
    init(viewModel: UserViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    private let signOutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Çıkış Yap", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemRed
        button.layer.cornerRadius = 20
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.layer.shadowColor = UIColor.systemRed.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowOpacity = 0.3
        button.layer.shadowRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private enum Section: Int, CaseIterable {
        case profile
        case appearance
        case notifications
        case account
        
        var title: String {
            switch self {
            case .profile: return "Profil"
            case .appearance: return "Görünüm"
            case .notifications: return "Bildirimler"
            case .account: return "Hesap"
            }
        }
        
        var items: [SettingsItem] {
            switch self {
            case .profile:
                return [
                    .init(title: "Avatarımı Değiştir", icon: "person.crop.circle.fill"),
                    .init(title: "İsmi Değiştir", icon: "pencil")
                ]
            case .appearance:
                return [
                    .init(title: "Tema", icon: "moon.circle.fill"),
                    .init(title: "Dil", icon: "globe")
                ]
            case .notifications:
                return [
                    .init(title: "Quiz Hatırlatmaları", icon: "bell.fill"),
                    .init(title: "Özel Teklifler", icon: "tag.fill")
                ]
            case .account:
                return [
                    .init(title: "Şifre Değiştir", icon: "lock.fill"),
                    .init(title: "Hesabı Sil", icon: "trash.fill", isDestructive: true)
                ]
            }
        }
    }
    
    private struct SettingsItem {
        let title: String
        let icon: String
        var isDestructive: Bool = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        title = "Ayarlar"
        view.backgroundColor = .systemGroupedBackground
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Kapat",
            style: .done,
            target: self,
            action: #selector(closeTapped)
        )
        
        view.addSubview(tableView)
        view.addSubview(signOutButton)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: signOutButton.topAnchor, constant: -20),
            
            signOutButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            signOutButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            signOutButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            signOutButton.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingsCell")
        
        signOutButton.addTarget(self, action: #selector(signOutTapped), for: .touchUpInside)
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
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    private func handleProfilePhotoChange() {
        let alert = UIAlertController(title: "Avatar Seç", message: "Karakterini seç", preferredStyle: .actionSheet)
        
        for avatar in Avatar.allCases {
            let action = UIAlertAction(title: avatar.displayName, style: .default) { [weak self] _ in
                self?.viewModel.updateAvatar(avatar.rawValue) { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            self?.showErrorAlert(error)
                        } else {
                            self?.showSuccessAlert(message: "Avatarınız başarıyla güncellendi.")
                        }
                    }
                }
            }
            
            // Avatar önizleme resmi
            if let image = avatar.image {
                let size = CGSize(width: 30, height: 30)
                UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
                let rect = CGRect(origin: .zero, size: size)
                
                // Arkaplan rengi
                avatar.backgroundColor.setFill()
                UIBezierPath(roundedRect: rect, cornerRadius: 8).fill()
                
                // Avatar resmi
                image.draw(in: rect.insetBy(dx: 4, dy: 4))
                
                let finalImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                action.setValue(finalImage?.withRenderingMode(.alwaysOriginal), forKey: "image")
            }
            
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel))
        present(alert, animated: true)
    }
    
    private func handleNameChange() {
        let alert = UIAlertController(
            title: "İsim Değiştir",
            message: "Yeni isminizi girin",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "Yeni isminiz"
            textField.autocapitalizationType = .words
        }
        
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel))
        alert.addAction(UIAlertAction(title: "Kaydet", style: .default) { [weak self] _ in
            guard let self = self,
                  let newName = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !newName.isEmpty else { return }
            
            self.viewModel.updateUserName(newName) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.showErrorAlert(error)
                    } else {
                        self.showSuccessAlert(message: "İsminiz başarıyla güncellendi.")
                    }
                }
            }
        })
        
        present(alert, animated: true)
    }
    
    private func handleThemeChange() {
        let alert = UIAlertController(title: "Tema Seçin", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Açık Tema", style: .default) { [weak self] _ in
            self?.viewModel.updateTheme(isDark: false)
        })
        
        alert.addAction(UIAlertAction(title: "Koyu Tema", style: .default) { [weak self] _ in
            self?.viewModel.updateTheme(isDark: true)
        })
        
        alert.addAction(UIAlertAction(title: "Sistem", style: .default) { [weak self] _ in
            if #available(iOS 13.0, *) {
                let scenes = UIApplication.shared.connectedScenes
                let windowScene = scenes.first as? UIWindowScene
                let window = windowScene?.windows.first
                window?.overrideUserInterfaceStyle = .unspecified
            }
        })
        
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func handleLanguageChange() {
        let alert = UIAlertController(title: "Dil Seçin", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Türkçe", style: .default) { [weak self] _ in
            self?.viewModel.updateLanguage("tr") { error in
                if let error = error {
                    self?.showErrorAlert(error)
                }
            }
        })
        
        alert.addAction(UIAlertAction(title: "English", style: .default) { [weak self] _ in
            self?.viewModel.updateLanguage("en") { error in
                if let error = error {
                    self?.showErrorAlert(error)
                }
            }
        })
        
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func handlePasswordChange() {
        let alert = UIAlertController(
            title: "Şifre Değiştir",
            message: "Yeni şifrenizi girin",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "Mevcut şifre"
            textField.isSecureTextEntry = true
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Yeni şifre"
            textField.isSecureTextEntry = true
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Yeni şifre tekrar"
            textField.isSecureTextEntry = true
        }
        
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel))
        alert.addAction(UIAlertAction(title: "Değiştir", style: .default) { [weak self] _ in
            guard let self = self,
                  let currentPassword = alert.textFields?[0].text,
                  let newPassword = alert.textFields?[1].text,
                  let confirmPassword = alert.textFields?[2].text,
                  !currentPassword.isEmpty,
                  !newPassword.isEmpty,
                  newPassword == confirmPassword else {
                self?.showErrorAlert(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Lütfen tüm alanları doldurun ve şifrelerin eşleştiğinden emin olun."]))
                return
            }
            
            self.viewModel.updatePassword(currentPassword: currentPassword, newPassword: newPassword) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.showErrorAlert(error)
                    } else {
                        self.showSuccessAlert(message: "Şifreniz başarıyla güncellendi.")
                    }
                }
            }
        })
        
        present(alert, animated: true)
    }
    
    private func handleAccountDeletion() {
        let alert = UIAlertController(
            title: "Hesabı Sil",
            message: "Hesabınızı silmek istediğinize emin misiniz? Bu işlem geri alınamaz.",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "Şifrenizi girin"
            textField.isSecureTextEntry = true
        }
        
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel))
        alert.addAction(UIAlertAction(title: "Sil", style: .destructive) { [weak self] _ in
            guard let self = self,
                  let password = alert.textFields?.first?.text,
                  !password.isEmpty else { return }
            
            self.viewModel.deleteAccount(password: password) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.showErrorAlert(error)
                    } else {
                        // Hesap başarıyla silindi, login ekranına yönlendir
                        let loginVC = LoginViewController()
                        loginVC.modalPresentationStyle = .fullScreen
                        self.present(loginVC, animated: true)
                    }
                }
            }
        })
        
        present(alert, animated: true)
    }
    
    private func showSuccessAlert(message: String) {
        let alert = UIAlertController(
            title: "Başarılı",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Settings TableView Delegate & DataSource
extension SettingsViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Section(rawValue: section)?.items.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Section(rawValue: section)?.title
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)
        
        guard let section = Section(rawValue: indexPath.section) else { return cell }
        let item = section.items[indexPath.row]
        
        var config = cell.defaultContentConfiguration()
        config.text = item.title
        config.image = UIImage(systemName: item.icon)
        
        if item.isDestructive {
            config.textProperties.color = .systemRed
            config.imageProperties.tintColor = .systemRed
        } else {
            config.textProperties.color = .label
            config.imageProperties.tintColor = .primaryPurple
        }
        
        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let section = Section(rawValue: indexPath.section) else { return }
        
        switch (section, indexPath.row) {
        case (.profile, 0): // Avatarımı Değiştir
            handleProfilePhotoChange()
        case (.profile, 1): // İsim Değiştirme
            handleNameChange()
        case (.appearance, 0): // Tema
            handleThemeChange()
        case (.appearance, 1): // Dil
            handleLanguageChange()
        case (.notifications, 0): // Quiz Hatırlatmaları
            handleQuizReminders()
        case (.notifications, 1): // Özel Teklifler
            handleSpecialOffers()
        case (.account, 0): // Şifre Değiştirme
            handlePasswordChange()
        case (.account, 1): // Hesap Silme
            handleAccountDeletion()
        default:
            break
        }
    }
    
    private func handleQuizReminders() {
        let alert = UIAlertController(
            title: "Quiz Hatırlatmaları",
            message: "Quiz hatırlatmalarını açmak/kapatmak için ayarlara yönlendirileceksiniz.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel))
        alert.addAction(UIAlertAction(title: "Ayarlara Git", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        
        present(alert, animated: true)
    }
    
    private func handleSpecialOffers() {
        let alert = UIAlertController(
            title: "Özel Teklifler",
            message: "Özel teklif bildirimlerini açmak/kapatmak için ayarlara yönlendirileceksiniz.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel))
        alert.addAction(UIAlertAction(title: "Ayarlara Git", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        
        present(alert, animated: true)
    }
} 
