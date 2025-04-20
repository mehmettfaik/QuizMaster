import UIKit
import Combine
import FirebaseFirestore
import FirebaseAuth

// MARK: - UIViewController Extension
extension UIViewController {
    func showErrorAlert(_ error: Error) {
        let alert = UIAlertController(
            title: LanguageManager.shared.localizedString(for: "error"),
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: LanguageManager.shared.localizedString(for: "ok"), style: .default))
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
        label.text = LanguageManager.shared.localizedString(for: "achievements")
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
        button.setTitle(LanguageManager.shared.localizedString(for: "my_friends"), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .primaryPurple
        button.layer.cornerRadius = 20
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.layer.shadowColor = UIColor.primaryPurple.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowOpacity = 0.3
        button.layer.shadowRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let onlineButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(LanguageManager.shared.localizedString(for: "online_button"), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemGreen
        button.layer.cornerRadius = 20
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.layer.shadowColor = UIColor.systemGreen.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowOpacity = 0.3
        button.layer.shadowRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let multiplayerService = MultiplayerGameService.shared
    private var invitationListener: ListenerRegistration?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = false
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.title = LanguageManager.shared.localizedString(for: "profile")
        setupUI()
        setupCollectionView()
        setupBindings()
        setupNavigationBar()
        setupInvitationListener()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadUserProfile()
        if let currentUserId = Auth.auth().currentUser?.uid {
            multiplayerService.updateOnlineStatus(userId: currentUserId, isOnline: false)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let currentUserId = Auth.auth().currentUser?.uid {
            multiplayerService.updateOnlineStatus(userId: currentUserId, isOnline: false)
        }
        invitationListener?.remove()
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
        contentView.addSubview(onlineButton)
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
            friendsButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            friendsButton.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.42),
            friendsButton.heightAnchor.constraint(equalToConstant: 50),
            
            onlineButton.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 40),
            onlineButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            onlineButton.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.42),
            onlineButton.heightAnchor.constraint(equalToConstant: 50),
            
            achievementsLabel.topAnchor.constraint(equalTo: friendsButton.bottomAnchor, constant: 40),
            achievementsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            achievementsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            achievementsCollectionView.topAnchor.constraint(equalTo: achievementsLabel.bottomAnchor, constant: 24),
            achievementsCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            achievementsCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            achievementsCollectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
        
        // Profil fotoğrafı için placeholder
        profileImageView.image = UIImage(systemName: "person.circle.fill")
        profileImageView.tintColor = .primaryPurple
        profileImageView.backgroundColor = .systemGray6
        
        // Add action to friends button
        friendsButton.addTarget(self, action: #selector(friendsButtonTapped), for: .touchUpInside)
        
        onlineButton.addTarget(self, action: #selector(onlineButtonTapped), for: .touchUpInside)
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
    
    @objc private func onlineButtonTapped() {
        let onlineVC = OnlineUsersViewController()
        navigationController?.pushViewController(onlineVC, animated: true)
    }
    
    private func setupInvitationListener() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        invitationListener = multiplayerService.listenForGameInvitations { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let game):
                    self?.handleGameInvitation(game)
                case .failure(let error):
                    print("Error listening for game invitations: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func handleGameInvitation(_ game: MultiplayerGame) {
        guard presentedViewController == nil else { return }
        
        let alert = UIAlertController(
            title: LanguageManager.shared.localizedString(for: "game_invitation"),
            message: String(format: LanguageManager.shared.localizedString(for: "game_invitation_message"), game.creatorName),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: LanguageManager.shared.localizedString(for: "accept"), style: .default) { [weak self] _ in
            self?.acceptGameInvitation(game)
        })
        
        alert.addAction(UIAlertAction(title: LanguageManager.shared.localizedString(for: "decline"), style: .destructive) { [weak self] _ in
            self?.declineGameInvitation(game)
        })
        
        present(alert, animated: true)
    }

    private func acceptGameInvitation(_ game: MultiplayerGame) {
        multiplayerService.respondToGameInvitation(gameId: game.id, accept: true) { [weak self] result in
            switch result {
            case .success(let game):
                DispatchQueue.main.async {
                    let waitingVC = GameWaitingViewController(game: game)
                    self?.navigationController?.pushViewController(waitingVC, animated: true)
                }
            case .failure(let error):
                print("Error accepting game invitation: \(error.localizedDescription)")
            }
        }
    }

    private func declineGameInvitation(_ game: MultiplayerGame) {
        multiplayerService.respondToGameInvitation(gameId: game.id, accept: false) { result in
            if case .failure(let error) = result {
                print("Error declining game invitation: \(error.localizedDescription)")
            }
        }
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
            message: """
            \(achievement.description)

            \(LanguageManager.shared.localizedString(for: "achievement_progress")): \(achievement.currentValue)/\(achievement.requirement)
            """,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title:LanguageManager.shared.localizedString(for: "ok"), style: .default))
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        progressView.progress = 0
        progressView.isHidden = false
        progressLabel.isHidden = false
    }
    
    func configure(with achievement: AchievementBadge) {
        titleLabel.text = achievement.title
        descriptionLabel.text = achievement.description
        
        // Check if the icon is an emoji (single character) or SF Symbol
        if achievement.icon.count == 1 {
            iconImageView.image = nil
            iconImageView.backgroundColor = .clear
            let label = UILabel()
            label.text = achievement.icon
            label.font = .systemFont(ofSize: 24)
            let size = CGSize(width: 24, height: 24)
            UIGraphicsBeginImageContextWithOptions(size, false, 0)
            if let context = UIGraphicsGetCurrentContext() {
                label.layer.render(in: context)
                iconImageView.image = UIGraphicsGetImageFromCurrentImageContext()
            }
            UIGraphicsEndImageContext()
        } else {
            iconImageView.image = UIImage(systemName: achievement.icon)
        }
        
        iconImageView.tintColor = achievement.isUnlocked ? .primaryPurple : .gray
        
        // Progress bar'ı güncelle
        progressView.setProgress(Float(achievement.progress), animated: true)
        progressLabel.text = "\(achievement.currentValue)/\(achievement.requirement)"
        
        // Progress bar ve label'ı göster
        progressView.isHidden = false
        progressLabel.isHidden = false
        
        // Kilitsiz/kilitli duruma göre opacity ayarla
        containerView.alpha = achievement.isUnlocked ? 1.0 : 0.7
        iconContainerView.backgroundColor = achievement.isUnlocked ? .primaryPurple.withAlphaComponent(0.1) : .systemGray5
    }
    
    func configureAsPlaceholder() {
        titleLabel.text = LanguageManager.shared.localizedString(for: "no_badges_yet")
        descriptionLabel.text = LanguageManager.shared.localizedString(for: "earn_badges_message")
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
    
    private enum Section: Int, CaseIterable {
        case profile
        case appearance
        case notifications
        case account
        
        var title: String {
            switch self {
            case .profile: return LanguageManager.shared.localizedString(for: "profile")
            case .appearance: return LanguageManager.shared.localizedString(for: "appearance")
            case .notifications: return LanguageManager.shared.localizedString(for: "notifications")
            case .account: return LanguageManager.shared.localizedString(for: "account")
            }
        }
        
        var items: [SettingsItem] {
            switch self {
            case .profile:
                return [
                    .init(title: LanguageManager.shared.localizedString(for: "change_avatar"), icon: "person.crop.circle.fill"),
                    .init(title: LanguageManager.shared.localizedString(for: "change_name"), icon: "pencil")
                ]
            case .appearance:
                return [
                    .init(title: LanguageManager.shared.localizedString(for: "language"), icon: "globe")
                ]
            case .notifications:
                return [
                    .init(title: LanguageManager.shared.localizedString(for: "quiz_reminders"), icon: "bell.fill"),
                    .init(title: LanguageManager.shared.localizedString(for: "special_offers"), icon: "tag.fill")
                ]
            case .account:
                return [
                    .init(title: LanguageManager.shared.localizedString(for: "change_password"), icon: "lock.fill"),
                    .init(title: LanguageManager.shared.localizedString(for: "delete_account"), icon: "trash.fill", isDestructive: true),
                    .init(title: LanguageManager.shared.localizedString(for: "logout"), icon: "rectangle.portrait.and.arrow.right", isDestructive: true)
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
        title = LanguageManager.shared.localizedString(for: "settings")
        view.backgroundColor = .systemGroupedBackground
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: LanguageManager.shared.localizedString(for: "close"),
            style: .done,
            target: self,
            action: #selector(closeTapped)
        )
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingsCell")
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    private func handleProfilePhotoChange() {
        let avatarVC = AvatarSelectionViewController(viewModel: viewModel)
        let navController = UINavigationController(rootViewController: avatarVC)
        present(navController, animated: true)
    }
    
    private func handleNameChange() {
        let alert = UIAlertController(
            title: LanguageManager.shared.localizedString(for: "change_name"),
            message: LanguageManager.shared.localizedString(for: "enter_new_name"),
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = LanguageManager.shared.localizedString(for: "new_name")
            textField.autocapitalizationType = .words
        }
        
        alert.addAction(UIAlertAction(title: LanguageManager.shared.localizedString(for: "cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: LanguageManager.shared.localizedString(for: "save"), style: .default) { [weak self] _ in
            guard let self = self,
                  let newName = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !newName.isEmpty else { return }
            
            self.viewModel.updateUserName(newName) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.showErrorAlert(error)
                    } else {
                        self.showSuccessAlert(message: LanguageManager.shared.localizedString(for: "name_updated"))
                    }
                }
            }
        })
        
        present(alert, animated: true)
    }
    
    private func handleLanguageChange() {
        let languageVC = LanguageSelectionViewController(viewModel: viewModel)
        let navController = UINavigationController(rootViewController: languageVC)
        navController.modalPresentationStyle = .formSheet
        present(navController, animated: true)
    }
    
    private func handlePasswordChange() {
        let alert = UIAlertController(
            title: LanguageManager.shared.localizedString(for: "change_password"),
            message: LanguageManager.shared.localizedString(for: "enter_new_password"),
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = LanguageManager.shared.localizedString(for: "current_password")
            textField.isSecureTextEntry = true
        }
        
        alert.addTextField { textField in
            textField.placeholder = LanguageManager.shared.localizedString(for: "new_password")
            textField.isSecureTextEntry = true
        }
        
        alert.addTextField { textField in
            textField.placeholder = LanguageManager.shared.localizedString(for: "confirm_new_password")
            textField.isSecureTextEntry = true
        }
        
        alert.addAction(UIAlertAction(title: LanguageManager.shared.localizedString(for: "cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: LanguageManager.shared.localizedString(for: "change"), style: .default) { [weak self] _ in
            guard let self = self,
                  let currentPassword = alert.textFields?[0].text,
                  let newPassword = alert.textFields?[1].text,
                  let confirmPassword = alert.textFields?[2].text,
                  !currentPassword.isEmpty,
                  !newPassword.isEmpty,
                  newPassword == confirmPassword else {
                self?.showErrorAlert(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: LanguageManager.shared.localizedString(for: "password_fields_error")]))
                return
            }
            
            self.viewModel.updatePassword(currentPassword: currentPassword, newPassword: newPassword) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.showErrorAlert(error)
                    } else {
                        self.showSuccessAlert(message: LanguageManager.shared.localizedString(for: "password_updated"))
                    }
                }
            }
        })
        
        present(alert, animated: true)
    }
    
    private func handleAccountDeletion() {
        let alert = UIAlertController(
            title: LanguageManager.shared.localizedString(for: "delete_account"),
            message: LanguageManager.shared.localizedString(for: "delete_account_confirmation"),
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = LanguageManager.shared.localizedString(for: "enter_password")
            textField.isSecureTextEntry = true
        }
        
        alert.addAction(UIAlertAction(title: LanguageManager.shared.localizedString(for: "cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: LanguageManager.shared.localizedString(for: "delete"), style: .destructive) { [weak self] _ in
            guard let self = self,
                  let password = alert.textFields?.first?.text,
                  !password.isEmpty else { return }
            
            self.viewModel.deleteAccount(password: password) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.showErrorAlert(error)
                    } else {
                        let loginVC = LoginViewController()
                        loginVC.modalPresentationStyle = .fullScreen
                        self.present(loginVC, animated: true)
                    }
                }
            }
        })
        
        present(alert, animated: true)
    }
    
    private func handleSignOut() {
        let alert = UIAlertController(
            title: LanguageManager.shared.localizedString(for: "logout"),
            message: LanguageManager.shared.localizedString(for: "logout_confirmation"),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: LanguageManager.shared.localizedString(for: "cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: LanguageManager.shared.localizedString(for: "logout"), style: .destructive) { [weak self] _ in
            self?.viewModel.signOut()
            let loginVC = LoginViewController()
            loginVC.modalPresentationStyle = .fullScreen
            self?.present(loginVC, animated: true)
        })
        
        present(alert, animated: true)
    }
    
    private func showSuccessAlert(message: String) {
        let alert = UIAlertController(
            title: LanguageManager.shared.localizedString(for: "success"),
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: LanguageManager.shared.localizedString(for: "ok"), style: .default))
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
        case (.appearance, 0): // Dil
            handleLanguageChange()
        case (.notifications, 0): // Quiz Hatırlatmaları
            handleQuizReminders()
        case (.notifications, 1): // Özel Teklifler
            handleSpecialOffers()
        case (.account, 0): // Şifre Değiştirme
            handlePasswordChange()
        case (.account, 1): // Hesap Silme
            handleAccountDeletion()
        case (.account, 2): // Çıkış Yap
            handleSignOut()
        default:
            break
        }
    }
    
    private func handleQuizReminders() {
        let alert = UIAlertController(
            title: LanguageManager.shared.localizedString(for: "quiz_reminders"),
            message: LanguageManager.shared.localizedString(for: "quiz_reminders_settings_message"),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: LanguageManager.shared.localizedString(for: "cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: LanguageManager.shared.localizedString(for: "go_to_settings"), style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        
        present(alert, animated: true)
    }
    
    private func handleSpecialOffers() {
        let alert = UIAlertController(
            title: LanguageManager.shared.localizedString(for: "special_offers"),
            message: LanguageManager.shared.localizedString(for: "special_offers_settings_message"),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: LanguageManager.shared.localizedString(for: "cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: LanguageManager.shared.localizedString(for: "go_to_settings"), style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        
        present(alert, animated: true)
    }
}

// MARK: - Language Selection View Controller
class LanguageSelectionViewController: UITableViewController {
    private let viewModel: UserViewModel
    
    private let languages: [(code: String, name: String, flag: String)] = [
        ("tr", "Türkçe", "🇹🇷"),
        ("en", "English", "🇬🇧")
    ]
    
    init(viewModel: UserViewModel) {
        self.viewModel = viewModel
        super.init(style: .insetGrouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        title = LanguageManager.shared.localizedString(for: "language")
        view.backgroundColor = .systemGroupedBackground
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "LanguageCell")
        tableView.rowHeight = 60
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return languages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LanguageCell", for: indexPath)
        let language = languages[indexPath.row]
        
        var config = cell.defaultContentConfiguration()
        
        // Ana başlık
        config.text = language.name
        config.textProperties.font = .systemFont(ofSize: 18, weight: .semibold)
        config.textProperties.color = .label
        
        // Bayrak emoji'sini büyük göster
        let flagAttachment = NSTextAttachment()
        let flagFont = UIFont.systemFont(ofSize: 30)
        flagAttachment.bounds = CGRect(x: 0, y: (flagFont.capHeight - 30) / 2, width: 30, height: 30)
        let flagString = language.flag as NSString
        flagAttachment.image = flagString.image(with: flagFont)
        
        config.image = flagAttachment.image
        config.imageProperties.maximumSize = CGSize(width: 40, height: 40)
        config.imageProperties.cornerRadius = 20
        
        // Hücre düzeni ayarları
        config.imageToTextPadding = 15
        config.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        
        cell.contentConfiguration = config
        
        // Seçili dili işaretle
        let currentLanguage = LanguageManager.shared.currentLanguage
        cell.accessoryType = language.code == currentLanguage ? .checkmark : .none
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedLanguage = languages[indexPath.row]
        viewModel.updateLanguage(selectedLanguage.code) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.showErrorAlert(error)
                } else {
                    // Önce mevcut view controller'ı kapat
                    self?.dismiss(animated: true) {
                        // Sonra uygulamayı yeniden başlat
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let sceneDelegate = windowScene.delegate as? SceneDelegate {
                            sceneDelegate.resetRootViewController()
                        }
                    }
                }
            }
        }
    }
}

// NSString extension for emoji flag rendering
extension NSString {
    func image(with font: UIFont) -> UIImage? {
        let size = self.size(withAttributes: [.font: font])
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        self.draw(at: .zero, withAttributes: [.font: font])
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

// MARK: - Avatar Selection View Controller
class AvatarSelectionViewController: UIViewController {
    private let viewModel: UserViewModel
    private var selectedAvatar: Avatar?
    
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 20
        layout.minimumInteritemSpacing = 20
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    init(viewModel: UserViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
    }
    
    private func setupUI() {
        title = LanguageManager.shared.localizedString(for: "select_avatar")
        view.backgroundColor = .systemBackground
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: LanguageManager.shared.localizedString(for: "save"),
            style: .done,
            target: self,
            action: #selector(saveTapped)
        )
        
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(AvatarCell.self, forCellWithReuseIdentifier: "AvatarCell")
    }
    
    @objc private func saveTapped() {
        guard let selectedAvatar = selectedAvatar else { return }
        
        viewModel.updateAvatar(selectedAvatar.rawValue) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.showErrorAlert(error)
                } else {
                    self?.dismiss(animated: true)
                }
            }
        }
    }
}

// MARK: - Avatar Collection View Cell
class AvatarCell: UICollectionViewCell {
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 20
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.clear.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
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
        containerView.addSubview(imageView)
        containerView.addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            imageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 90),
            imageView.heightAnchor.constraint(equalToConstant: 90),
            
            nameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            nameLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
    }
    
    func configure(with avatar: Avatar, isSelected: Bool) {
        imageView.image = avatar.image
        nameLabel.text = avatar.displayName
        containerView.backgroundColor = .white
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 6
        containerView.layer.shadowOpacity = 0.1
        
        if isSelected {
            containerView.layer.borderColor = UIColor.primaryPurple.cgColor
            containerView.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
        } else {
            containerView.layer.borderColor = UIColor.clear.cgColor
            containerView.transform = .identity
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        containerView.layer.borderColor = UIColor.clear.cgColor
        containerView.transform = .identity
    }
}

// MARK: - Avatar Selection Collection View Extensions
extension AvatarSelectionViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Avatar.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AvatarCell", for: indexPath) as! AvatarCell
        let avatar = Avatar.allCases[indexPath.item]
        cell.configure(with: avatar, isSelected: selectedAvatar == avatar)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 20) / 2
        return CGSize(width: width, height: width * 1.2)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let avatar = Avatar.allCases[indexPath.item]
        selectedAvatar = avatar
        collectionView.reloadData()
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
} 
