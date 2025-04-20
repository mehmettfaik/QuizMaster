import UIKit
import FirebaseFirestore
import FirebaseAuth

class GameWaitingViewController: UIViewController {
    private let multiplayerService = MultiplayerGameService.shared
    private var invitationListener: ListenerRegistration?
    private var gameListener: ListenerRegistration?
    private var game: MultiplayerGame?
    
    init(game: MultiplayerGame? = nil) {
        self.game = game
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "Waiting for opponent..."
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .center
        label.textColor = .darkGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .primaryPurple
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        if let game = game {
            statusLabel.text = "Waiting for game to start..."
            listenForGameStart(game)
        } else {
            setupListeners()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        invitationListener?.remove()
        gameListener?.remove()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Game Invitation"
        
        view.addSubview(statusLabel)
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 20)
        ])
        
        activityIndicator.startAnimating()
    }
    
    private func setupListeners() {
        // Listen for incoming game invitations
        invitationListener = multiplayerService.listenForGameInvitations { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let game):
                    // Only show invitation if we haven't handled it yet
                    if !self.isShowingInvitation {
                        self.handleGameInvitation(game)
                    }
                case .failure(let error):
                    print("Error listening for game invitations: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private var isShowingInvitation = false
    
    private func listenForGameStart(_ game: MultiplayerGame) {
        gameListener?.remove() // Remove any existing listener
        
        statusLabel.text = "Waiting for game to start..."
        
        gameListener = multiplayerService.listenForGameUpdates(gameId: game.id) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let updatedGame):
                    self?.handleGameStatusUpdate(updatedGame)
                case .failure(let error):
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }
    
    private func handleGameStatusUpdate(_ game: MultiplayerGame) {
        switch game.status {
        case .inProgress:
            let gameVC = MultiplayerGameViewController(game: game)
            navigationController?.pushViewController(gameVC, animated: true)
        case .rejected:
            showAlert(title: "Game Cancelled", message: "The game has been cancelled.") { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            }
        case .accepted:
            if game.creatorId == Auth.auth().currentUser?.uid {
                statusLabel.text = "Game accepted! Select category and difficulty to start."
            } else {
                statusLabel.text = "Waiting for \(game.creatorName) to start the game..."
            }
        case .pending:
            statusLabel.text = "Waiting for response..."
        case .completed:
            showAlert(title: "Game Over", message: "The game has ended.") { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            }
        case .cancelled:
            showAlert(title: "Game Cancelled", message: "The game has been cancelled by the other player.") { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    private func handleGameInvitation(_ game: MultiplayerGame) {
        isShowingInvitation = true
        
        let alert = UIAlertController(
            title: "Game Invitation",
            message: "\(game.creatorName) has invited you to play a quiz game!",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Accept", style: .default) { [weak self] _ in
            self?.isShowingInvitation = false
            self?.acceptInvitation(game)
        })
        
        alert.addAction(UIAlertAction(title: "Decline", style: .destructive) { [weak self] _ in
            self?.isShowingInvitation = false
            self?.declineInvitation(game)
        })
        
        // If alert is already being presented, dismiss it first
        if let presentedVC = presentedViewController {
            presentedVC.dismiss(animated: true) { [weak self] in
                self?.present(alert, animated: true)
            }
        } else {
            present(alert, animated: true)
        }
    }
    
    private func acceptInvitation(_ game: MultiplayerGame) {
        statusLabel.text = "Accepting invitation..."
        activityIndicator.startAnimating()
        
        multiplayerService.respondToGameInvitation(gameId: game.id, accept: true) { [weak self] result in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                
                switch result {
                case .success(let updatedGame):
                    self?.statusLabel.text = "Waiting for \(updatedGame.creatorName) to start the game..."
                    self?.listenForGameStart(updatedGame)
                case .failure(let error):
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }
    
    private func declineInvitation(_ game: MultiplayerGame) {
        statusLabel.text = "Declining invitation..."
        activityIndicator.startAnimating()
        
        multiplayerService.respondToGameInvitation(gameId: game.id, accept: false) { [weak self] result in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                
                switch result {
                case .success:
                    self?.navigationController?.popViewController(animated: true)
                case .failure(let error):
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String, completion: ((UIAlertAction) -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: completion))
        present(alert, animated: true)
    }
} 
