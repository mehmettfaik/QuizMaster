import UIKit

class FriendUserCell: UITableViewCell {
    static let identifier = "FriendUserCell"
    
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
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textAlignment = .center
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        containerView.addSubview(avatarImageView)
        containerView.addSubview(nameLabel)
        containerView.addSubview(emailLabel)
        containerView.addSubview(statusLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            avatarImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            avatarImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 50),
            avatarImageView.heightAnchor.constraint(equalToConstant: 50),
            
            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: statusLabel.leadingAnchor, constant: -8),
            
            emailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            emailLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            emailLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            emailLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            
            statusLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            statusLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 90),
            statusLabel.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    func configure(with user: FriendUser, hasRequestPending: Bool, isFriend: Bool) {
        nameLabel.text = user.name
        emailLabel.text = user.email
        
        if isFriend {
            statusLabel.text = "Arkadaş"
            statusLabel.backgroundColor = .systemGreen.withAlphaComponent(0.1)
            statusLabel.textColor = .systemGreen
            statusLabel.isHidden = false
        } else if hasRequestPending {
            statusLabel.text = "İstek Gönderildi"
            statusLabel.backgroundColor = .secondaryPurple.withAlphaComponent(0.1)
            statusLabel.textColor = .secondaryPurple
            statusLabel.isHidden = false
        } else {
            statusLabel.isHidden = true
        }
        
        // Avatar ayarla
        if let avatarImage = UIImage(named: user.avatar) {
            avatarImageView.image = avatarImage
            avatarImageView.backgroundColor = .clear
        } else {
            let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .regular)
            avatarImageView.image = UIImage(systemName: "person.circle.fill", withConfiguration: config)
            avatarImageView.backgroundColor = .secondaryPurple.withAlphaComponent(0.1)
        }
    }
} 