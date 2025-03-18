import UIKit
import FirebaseFirestore

protocol FriendRequestCellDelegate: AnyObject {
    func didTapAccept(for request: FriendRequest)
    func didTapReject(for request: FriendRequest)
}

class FriendRequestCell: UITableViewCell {
    static let identifier = "FriendRequestCell"
    
    weak var delegate: FriendRequestCellDelegate?
    private var friendRequest: FriendRequest?
    private let db = Firestore.firestore()
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .secondaryPurple.withAlphaComponent(0.1)
        imageView.tintColor = .primaryPurple
        imageView.layer.cornerRadius = 25
        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .regular)
        imageView.image = UIImage(systemName: "person.circle.fill", withConfiguration: config)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let emailLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let buttonsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.distribution = .fillEqually
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private lazy var acceptButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 25, weight: .medium)
        let image = UIImage(systemName: "checkmark.circle.fill", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .systemGreen
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handleAccept), for: .touchUpInside)
        return button
    }()
    
    private lazy var rejectButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 25, weight: .medium)
        let image = UIImage(systemName: "xmark.circle.fill", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .systemRed
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handleReject), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        containerView.addSubview(avatarImageView)
        containerView.addSubview(nameLabel)
        containerView.addSubview(emailLabel)
        
        buttonsStackView.addArrangedSubview(acceptButton)
        buttonsStackView.addArrangedSubview(rejectButton)
        containerView.addSubview(buttonsStackView)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            containerView.heightAnchor.constraint(equalToConstant: 140),
            
            avatarImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            avatarImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 50),
            avatarImageView.heightAnchor.constraint(equalToConstant: 50),
            
            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: buttonsStackView.leadingAnchor, constant: -8),
            
            emailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            emailLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            emailLabel.trailingAnchor.constraint(lessThanOrEqualTo: buttonsStackView.leadingAnchor, constant: -12),
            
            buttonsStackView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            buttonsStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            buttonsStackView.widthAnchor.constraint(equalToConstant: 100),
            
            acceptButton.heightAnchor.constraint(equalToConstant: 40),
            acceptButton.widthAnchor.constraint(equalToConstant: 40),
            rejectButton.heightAnchor.constraint(equalToConstant: 40),
            rejectButton.widthAnchor.constraint(equalToConstant: 40)
        ])
        
        avatarImageView.layer.cornerRadius = 35
    }
    
    // MARK: - Actions
    @objc private func handleAccept() {
        guard let request = friendRequest else { return }
        delegate?.didTapAccept(for: request)
        
        UIView.animate(withDuration: 0.2) {
            self.acceptButton.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        } completion: { _ in
            UIView.animate(withDuration: 0.2) {
                self.acceptButton.transform = .identity
            }
        }
    }
    
    @objc private func handleReject() {
        guard let request = friendRequest else { return }
        delegate?.didTapReject(for: request)
        
        UIView.animate(withDuration: 0.2) {
            self.rejectButton.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        } completion: { _ in
            UIView.animate(withDuration: 0.2) {
                self.rejectButton.transform = .identity
            }
        }
    }
    
    // MARK: - Configuration
    func configure(with request: FriendRequest) {
        self.friendRequest = request
        emailLabel.text = request.senderEmail
        
        db.collection("users").document(request.senderId).getDocument { [weak self] snapshot, error in
            guard let self = self,
                  let data = snapshot?.data(),
                  let name = data["name"] as? String,
                  let avatar = data["avatar"] as? String else {
                DispatchQueue.main.async {
                    if let self = self {
                        self.nameLabel.text = "Kullanıcı"
                        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .regular)
                        self.avatarImageView.image = UIImage(systemName: "person.circle.fill", withConfiguration: config)
                        self.avatarImageView.backgroundColor = .secondaryPurple.withAlphaComponent(0.1)
                    }
                }
                return
            }
            
            DispatchQueue.main.async {
                self.nameLabel.text = name.capitalized
                
                if let avatarImage = UIImage(named: avatar) {
                    self.avatarImageView.image = avatarImage
                    self.avatarImageView.backgroundColor = .clear
                } else {
                    let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .regular)
                    self.avatarImageView.image = UIImage(systemName: "person.circle.fill", withConfiguration: config)
                    self.avatarImageView.backgroundColor = .secondaryPurple.withAlphaComponent(0.1)
                }
            }
        }
    }
}
