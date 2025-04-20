import UIKit
import FirebaseAuth

class LeaderboardCell: UITableViewCell {
    static let identifier = "LeaderboardCell"
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let rankLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .primaryPurple
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 25
        imageView.backgroundColor = .systemGray6
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .black
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let pointsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .systemIndigo
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let trendImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemGreen
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
            rankLabel.widthAnchor.constraint(equalToConstant: 40),
            
            avatarImageView.leadingAnchor.constraint(equalTo: rankLabel.trailingAnchor, constant: 12),
            avatarImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 50),
            avatarImageView.heightAnchor.constraint(equalToConstant: 50),
            
            trendImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            trendImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            trendImageView.widthAnchor.constraint(equalToConstant: 24),
            trendImageView.heightAnchor.constraint(equalToConstant: 24),
            
            pointsLabel.trailingAnchor.constraint(equalTo: trendImageView.leadingAnchor, constant: -8),
            pointsLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            pointsLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
            
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            nameLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: pointsLabel.leadingAnchor, constant: -8)
        ])
    }
    
    func configure(with user: User, rank: Int) {
        // Configure rank with special styling for top 3
        if rank <= 3 {
            rankLabel.text = "#\(rank)"
            rankLabel.font = .systemFont(ofSize: 24, weight: .bold)
            
            switch rank {
            case 1:
                rankLabel.textColor = UIColor(red: 1, green: 0.84, blue: 0, alpha: 1) // Gold
            case 2:
                rankLabel.textColor = UIColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 1) // Silver
            case 3:
                rankLabel.textColor = UIColor(red: 0.8, green: 0.5, blue: 0.2, alpha: 1) // Bronze
            default:
                break
            }
        } else {
            rankLabel.text = "#\(rank)"
            rankLabel.font = .systemFont(ofSize: 20, weight: .bold)
            rankLabel.textColor = .darkGray
        }
        
        nameLabel.text = user.name
        pointsLabel.text = "\(user.totalPoints) \(LanguageManager.shared.localizedString(for: "points"))"
        
        // İsim uzunluğuna göre font boyutunu ayarla
        let maxWidth = containerView.frame.width - 250 // Avatar, rank, points ve trend için boşluk bırak
        let currentFont = UIFont.systemFont(ofSize: 16, weight: .semibold)
        let size = (user.name as NSString).size(withAttributes: [.font: currentFont])
        
        if size.width > maxWidth {
            nameLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        } else {
            nameLabel.font = currentFont
        }
        
        if let avatarType = Avatar(rawValue: user.avatar) {
            avatarImageView.image = avatarType.image
            avatarImageView.backgroundColor = avatarType.backgroundColor
        }
        
        // Highlight current user's row
        if user.id == Auth.auth().currentUser?.uid {
            containerView.backgroundColor = .primaryPurple.withAlphaComponent(0.1)
            containerView.layer.borderWidth = 1
            containerView.layer.borderColor = UIColor.primaryPurple.cgColor
        } else {
            containerView.backgroundColor = .white
            containerView.layer.borderWidth = 0
        }
        
        // Configure trend indicator (up/down arrow)
        if rank <= 3 {
            trendImageView.image = UIImage(systemName: "crown.fill")
            trendImageView.tintColor = rankLabel.textColor
        } else {
            trendImageView.image = UIImage(systemName: "arrow.up.circle.fill")
            trendImageView.tintColor = .systemGreen
        }
    }
} 
