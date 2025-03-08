import UIKit
import Combine

class ProfileViewController: UIViewController {
    private let viewModel = AuthViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .backgroundPurple
        imageView.layer.cornerRadius = 40
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let countryFlagImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "flag_hungary") // Replace with actual flag
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .black
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let statsView: UIView = {
        let view = UIView()
        view.backgroundColor = .primaryPurple
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let pointsLabel: UILabel = {
        let label = UILabel()
        label.text = "POINTS"
        label.font = .systemFont(ofSize: 12)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let pointsValueLabel: UILabel = {
        let label = UILabel()
        label.text = "590"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let rankLabel: UILabel = {
        let label = UILabel()
        label.text = "WORLD RANK"
        label.font = .systemFont(ofSize: 12)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let rankValueLabel: UILabel = {
        let label = UILabel()
        label.text = "#1,438"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let settingsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "gearshape.fill"), for: .normal)
        button.tintColor = .primaryPurple
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let signOutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign Out", for: .normal)
        button.setTitleColor(.red, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(profileImageView)
        view.addSubview(countryFlagImageView)
        view.addSubview(nameLabel)
        view.addSubview(statsView)
        view.addSubview(settingsButton)
        view.addSubview(signOutButton)
        
        statsView.addSubview(pointsLabel)
        statsView.addSubview(pointsValueLabel)
        statsView.addSubview(rankLabel)
        statsView.addSubview(rankValueLabel)
        
        NSLayoutConstraint.activate([
            profileImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 80),
            profileImageView.heightAnchor.constraint(equalToConstant: 80),
            
            countryFlagImageView.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: -20),
            countryFlagImageView.trailingAnchor.constraint(equalTo: profileImageView.trailingAnchor),
            countryFlagImageView.widthAnchor.constraint(equalToConstant: 24),
            countryFlagImageView.heightAnchor.constraint(equalToConstant: 24),
            
            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 16),
            nameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            statsView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 20),
            statsView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statsView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            statsView.heightAnchor.constraint(equalToConstant: 80),
            
            pointsLabel.leadingAnchor.constraint(equalTo: statsView.leadingAnchor, constant: 20),
            pointsLabel.centerYAnchor.constraint(equalTo: statsView.centerYAnchor, constant: -12),
            
            pointsValueLabel.leadingAnchor.constraint(equalTo: pointsLabel.leadingAnchor),
            pointsValueLabel.topAnchor.constraint(equalTo: pointsLabel.bottomAnchor, constant: 4),
            
            rankLabel.trailingAnchor.constraint(equalTo: statsView.trailingAnchor, constant: -20),
            rankLabel.centerYAnchor.constraint(equalTo: statsView.centerYAnchor, constant: -12),
            
            rankValueLabel.trailingAnchor.constraint(equalTo: rankLabel.trailingAnchor),
            rankValueLabel.topAnchor.constraint(equalTo: rankLabel.bottomAnchor, constant: 4),
            
            settingsButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            settingsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            settingsButton.widthAnchor.constraint(equalToConstant: 44),
            settingsButton.heightAnchor.constraint(equalToConstant: 44),
            
            signOutButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            signOutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        signOutButton.addTarget(self, action: #selector(signOutTapped), for: .touchUpInside)
    }
    
    private func setupBindings() {
        viewModel.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                if let user = user {
                    self?.nameLabel.text = user.name
                    // Update other user data
                }
            }
            .store(in: &cancellables)
    }
    
    @objc private func signOutTapped() {
        viewModel.signOut()
        let loginVC = LoginViewController()
        loginVC.modalPresentationStyle = .fullScreen
        present(loginVC, animated: true)
    }
} 