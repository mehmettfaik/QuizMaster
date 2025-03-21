import UIKit
import FirebaseAuth

class LeaderboardCell: UITableViewCell {
    static let identifier = "LeaderboardCell"
    
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
    
    private let rankLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 20
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let pointsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .primaryPurple
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let trendImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .gray
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
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
        containerView.addSubview(rankLabel)
        containerView.addSubview(avatarImageView)
        containerView.addSubview(nameLabel)
        containerView.addSubview(pointsLabel)
        containerView.addSubview(trendImageView)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            rankLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            rankLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            rankLabel.widthAnchor.constraint(equalToConstant: 30),
            
            avatarImageView.leadingAnchor.constraint(equalTo: rankLabel.trailingAnchor, constant: 12),
            avatarImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 40),
            avatarImageView.heightAnchor.constraint(equalToConstant: 40),
            
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            nameLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            pointsLabel.trailingAnchor.constraint(equalTo: trendImageView.leadingAnchor, constant: -8),
            pointsLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            trendImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            trendImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            trendImageView.widthAnchor.constraint(equalToConstant: 20),
            trendImageView.heightAnchor.constraint(equalToConstant: 20),
            
            containerView.heightAnchor.constraint(equalToConstant: 72)
        ])
    }
    
    func configure(with user: User, rank: Int, trend: Int = 0) {
        rankLabel.text = "#\(rank)"
        nameLabel.text = user.name
        pointsLabel.text = "\(user.totalPoints) 🏅"
        
        if let avatarType = Avatar(rawValue: user.avatar) {
            avatarImageView.image = avatarType.image
            avatarImageView.backgroundColor = avatarType.backgroundColor
        }
        
        // Configure trend indicator
        if trend > 0 {
            trendImageView.image = UIImage(systemName: "arrow.up.circle.fill")
            trendImageView.tintColor = .systemGreen
        } else if trend < 0 {
            trendImageView.image = UIImage(systemName: "arrow.down.circle.fill")
            trendImageView.tintColor = .systemRed
        } else {
            trendImageView.image = UIImage(systemName: "minus.circle.fill")
            trendImageView.tintColor = .systemGray
        }
        
        // Highlight current user
        if user.id == Auth.auth().currentUser?.uid {
            containerView.backgroundColor = .primaryPurple.withAlphaComponent(0.1)
            containerView.layer.borderWidth = 1
            containerView.layer.borderColor = UIColor.primaryPurple.cgColor
        } else {
            containerView.backgroundColor = .white
            containerView.layer.borderWidth = 0
        }
        
        // Special styling for top 3
        if rank <= 3 {
            rankLabel.textColor = .white
            rankLabel.font = .systemFont(ofSize: 20, weight: .bold)
            
            switch rank {
            case 1:
                rankLabel.backgroundColor = UIColor(red: 1, green: 0.84, blue: 0, alpha: 1) // Gold
            case 2:
                rankLabel.backgroundColor = UIColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 1) // Silver
            case 3:
                rankLabel.backgroundColor = UIColor(red: 0.8, green: 0.5, blue: 0.2, alpha: 1) // Bronze
            default:
                break
            }
            
            rankLabel.layer.cornerRadius = 15
            rankLabel.layer.masksToBounds = true
        } else {
            rankLabel.backgroundColor = .clear
            rankLabel.textColor = .black
            rankLabel.font = .systemFont(ofSize: 18, weight: .bold)
        }
    }
} 