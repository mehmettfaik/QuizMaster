import UIKit

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