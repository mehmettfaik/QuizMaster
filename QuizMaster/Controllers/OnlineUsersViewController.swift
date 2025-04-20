import UIKit
import FirebaseAuth
import FirebaseFirestore

class OnlineUsersViewController: UIViewController {
    private let tableView: UITableView = {
        let table = UITableView()
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        table.backgroundColor = .clear
        table.separatorStyle = .none
        return table
    }()
    
    private var onlineUsers: [User] = []
    private let multiplayerService = MultiplayerGameService.shared
    private var onlineUsersListener: ListenerRegistration?
    private var invitationListener: ListenerRegistration?
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 20
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = .zero
        view.layer.shadowRadius = 15
        view.layer.shadowOpacity = 0.2
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let warningLabel: UILabel = {
        let label = UILabel()
        label.text = LanguageManager.shared.localizedString(for: "friend_warning")
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .gray
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let titleLabel: UILabel = { 
        let label = UILabel()
        label.text = LanguageManager.shared.localizedString(for: "online_users")
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .primaryPurple
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupWave()
        setupUI()
        setupListeners()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let currentUserId = Auth.auth().currentUser?.uid {
            multiplayerService.updateOnlineStatus(userId: currentUserId, isOnline: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        onlineUsersListener?.remove()
        invitationListener?.remove()
        if let currentUserId = Auth.auth().currentUser?.uid {
            multiplayerService.updateOnlineStatus(userId: currentUserId, isOnline: false)
        }
    }
    
    private func setupNavigationBar() {
        // Make navigation bar transparent
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        
        // Set navigation bar tint color to white (affects back button)
        navigationController?.navigationBar.tintColor = .white
        
        // Set title color to white if needed
        navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.white
        ]
    }
    
    private func setupWave() {
        let purpleView = UIView()
        purpleView.backgroundColor = .primaryPurple
        purpleView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add bottom corners to purple view
        purpleView.layer.cornerRadius = 30
        purpleView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        
        view.addSubview(purpleView)
        
        NSLayoutConstraint.activate([
            purpleView.topAnchor.constraint(equalTo: view.topAnchor),
            purpleView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            purpleView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            purpleView.heightAnchor.constraint(equalToConstant: 120)
        ])
    }
    
    private func setupUI() {
        view.backgroundColor = .primaryPurple
        navigationItem.title = ""
        
        view.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(tableView)
        containerView.addSubview(warningLabel)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 15),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 15),
            tableView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 25),
            tableView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -25),
            tableView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -15),
            
            warningLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            warningLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            warningLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 30),
            warningLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -30)
        ])
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func setupListeners() {
        setupOnlineUsersListener()
        setupInvitationListener()
    }
    
    private func setupOnlineUsersListener() {
        onlineUsersListener = multiplayerService.getOnlineUsers { [weak self] users in
            DispatchQueue.main.async {
                self?.onlineUsers = users.filter { $0.id != Auth.auth().currentUser?.uid }
                self?.tableView.reloadData()
                self?.warningLabel.isHidden = !(self?.onlineUsers.isEmpty ?? true)
                self?.tableView.isHidden = self?.onlineUsers.isEmpty ?? true
            }
        }
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
        // Prevent showing duplicate invitations
        guard presentedViewController == nil else { return }
        
        let localizedText = LanguageManager.shared.localizedString(for: "key")
        
        let alert = UIAlertController(
            title: localizedText,
            message: "\(game.creatorName) has invited you to play a quiz game!",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Accept", style: .default) { [weak self] _ in
            self?.acceptGameInvitation(game)
        })
        
        alert.addAction(UIAlertAction(title: "Decline", style: .destructive) { [weak self] _ in
            self?.declineGameInvitation(game)
        })
        
        present(alert, animated: true)
    }
    
    private func acceptGameInvitation(_ game: MultiplayerGame) {
        multiplayerService.respondToGameInvitation(gameId: game.id, accept: true) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let game):
                    let waitingVC = GameWaitingViewController(game: game)
                    self?.navigationController?.pushViewController(waitingVC, animated: true)
                case .failure(let error):
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                }
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
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension OnlineUsersViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return onlineUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let user = onlineUsers[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = user.name
        content.secondaryText = "Online"
        content.textProperties.font = .systemFont(ofSize: 16, weight: .medium)
        content.secondaryTextProperties.font = .systemFont(ofSize: 14)
        content.secondaryTextProperties.color = .systemGreen
        
        // Add extra padding to content
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20)
        cell.contentConfiguration = content
        
        // Cell styling
        cell.backgroundColor = .clear // Changed to clear
        
        // Create a background view with enhanced shadow
        let backgroundView = UIView()
        backgroundView.backgroundColor = .white
        backgroundView.layer.cornerRadius = 12
        
        // Enhanced shadow settings
        backgroundView.layer.shadowColor = UIColor.black.cgColor
        backgroundView.layer.shadowOpacity = 0.2
        backgroundView.layer.shadowOffset = .zero
        backgroundView.layer.shadowRadius = 10
        
        // Important: Add these lines to make shadow visible on all sides
        backgroundView.layer.masksToBounds = false
        backgroundView.frame = cell.bounds.inset(by: UIEdgeInsets(top: 5, left: 8, bottom: 5, right: 8))
        
        cell.backgroundView = backgroundView
        
        // Remove selection style
        cell.selectionStyle = .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80 // Increased height to accommodate shadow
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .clear
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 15 // Increased spacing between cells
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let user = onlineUsers[indexPath.row]
        let alert = UIAlertController(
            title: "Oyuncuyu Davet Et",
            message: "\(user.name) adlı oyuncuya meydan okumak ister misiniz?",
            preferredStyle: .alert
        )
        
        let challengeAction = UIAlertAction(title: "Davet Et", style: .default) { [weak self] _ in
            self?.sendGameInvitation(to: user)
        }
        challengeAction.setValue(UIColor.primaryPurple, forKey: "titleTextColor")
        
        let cancelAction = UIAlertAction(title: LanguageManager.shared.localizedString(for: "cancel"), style: .cancel)
        
        alert.addAction(challengeAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    private func sendGameInvitation(to user: User) {
        multiplayerService.sendGameInvitation(to: user.id) { [weak self] result in
            switch result {
            case .success(let game):
                DispatchQueue.main.async {
                    let gameSetupVC = GameSetupViewController(game: game)
                    self?.navigationController?.pushViewController(gameSetupVC, animated: true)
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }
} 
