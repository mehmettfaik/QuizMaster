import UIKit

class CategoryCell: UICollectionViewCell {
    enum Style {
        case modern  // SearchViewController için
        case classic // HomeViewController için
    }
    
    private var style: Style = .classic
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let iconLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 70)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .left
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let questionsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .primaryPurple
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let favoriteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "heart"), for: .normal)
        button.tintColor = .red
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    var onFavoriteButtonTapped: (() -> Void)?
    private var categoryTitle: String = ""
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(iconLabel)
        containerView.addSubview(titleLabel)
        containerView.addSubview(questionsLabel)
        containerView.addSubview(subtitleLabel)
        containerView.addSubview(iconImageView)
        containerView.addSubview(favoriteButton)
        
        favoriteButton.addTarget(self, action: #selector(favoriteButtonTapped), for: .touchUpInside)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    private func applyClassicStyle() {
        backgroundColor = .clear
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 16
        
        iconLabel.isHidden = false
        titleLabel.font = .systemFont(ofSize: 18, weight: .medium)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .left
        subtitleLabel.isHidden = true
        iconImageView.isHidden = true
        favoriteButton.isHidden = true
        questionsLabel.isHidden = false
        
        // Reset constraints
        iconLabel.removeFromSuperview()
        titleLabel.removeFromSuperview()
        questionsLabel.removeFromSuperview()
        containerView.addSubview(iconLabel)
        containerView.addSubview(titleLabel)
        containerView.addSubview(questionsLabel)
        
        NSLayoutConstraint.activate([
            iconLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            iconLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            iconLabel.heightAnchor.constraint(equalToConstant: 72),
            iconLabel.widthAnchor.constraint(equalToConstant: 72),
            
            titleLabel.topAnchor.constraint(equalTo: iconLabel.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            questionsLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            questionsLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            questionsLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)
        ])
        
        // Gölge efekti
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 8
        containerView.layer.shadowOpacity = 0.1
        
        // Add appearance animation
        addIconAnimation()
    }
    
    private func addIconAnimation() {
        let category = categoryTitle.lowercased()
        
        switch category {
        case "vehicle":
            addDriveAnimation()
        case "science":
            addBubbleAnimation()
        case "sports":
            addBounceAnimation()
        case "history":
            addFlipAnimation()
        case "art":
            addRotateAnimation()
        default:
            addPulseAnimation()
        }
    }
    
    private func addDriveAnimation() {
        iconLabel.transform = CGAffineTransform(translationX: -50, y: 0)
        UIView.animate(withDuration: 1.0, delay: 0.2, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [.repeat, .autoreverse], animations: {
            self.iconLabel.transform = CGAffineTransform(translationX: 50, y: 0)
        })
    }
    
    private func addBubbleAnimation() {
        UIView.animate(withDuration: 1.0, delay: 0, options: [.repeat, .autoreverse], animations: {
            self.iconLabel.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            self.iconLabel.alpha = 0.7
        })
    }
    
    private func addBounceAnimation() {
        let jumpHeight: CGFloat = -200  // Çok daha yüksek zıplama
        
        // Başlangıç pozisyonunu ayarla
        iconLabel.transform = .identity
        
        let springTiming = UISpringTimingParameters(dampingRatio: 0.5, initialVelocity: CGVector(dx: 0, dy: 10))
        
        let animator = UIViewPropertyAnimator(duration: 2.0, timingParameters: springTiming)
        
        animator.addAnimations {
            UIView.animateKeyframes(withDuration: 2.0, delay: 0, options: [.calculationModeCubic], animations: {
                // İlk zıplama - Yükselme
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.3) {
                    self.iconLabel.transform = CGAffineTransform(translationX: 0, y: jumpHeight)
                        .rotated(by: .pi * 0.5)
                        .scaledBy(x: 0.7, y: 0.7)
                }
                
                // Düşme ve sıkışma
                UIView.addKeyframe(withRelativeStartTime: 0.3, relativeDuration: 0.2) {
                    self.iconLabel.transform = CGAffineTransform(translationX: 0, y: 0)
                        .scaledBy(x: 1.3, y: 0.7)
                }
                
                // İkinci zıplama - daha alçak
                UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.2) {
                    self.iconLabel.transform = CGAffineTransform(translationX: 0, y: jumpHeight/2)
                        .rotated(by: .pi)
                        .scaledBy(x: 0.8, y: 0.8)
                }
                
                // Son düşüş ve normale dönüş
                UIView.addKeyframe(withRelativeStartTime: 0.7, relativeDuration: 0.3) {
                    self.iconLabel.transform = .identity
                }
            })
        }
        
        animator.addCompletion { _ in
            // Animasyonu tekrarla
            self.addBounceAnimation()
        }
        
        animator.startAnimation()
    }
    
    private func addFlipAnimation() {
        UIView.animate(withDuration: 1.5, delay: 0, options: [.repeat], animations: {
            self.iconLabel.transform = CGAffineTransform(rotationAngle: .pi * 2)
        })
    }
    
    private func addRotateAnimation() {
        let rotation = CABasicAnimation(keyPath: "transform.rotation")
        rotation.fromValue = 0
        rotation.toValue = Double.pi * 2
        rotation.duration = 2
        rotation.repeatCount = .infinity
        iconLabel.layer.add(rotation, forKey: "rotationAnimation")
    }
    
    private func addPulseAnimation() {
        UIView.animate(withDuration: 1.0, delay: 0, options: [.repeat, .autoreverse], animations: {
            self.iconLabel.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        })
    }
    
    private func applyModernStyle() {
        backgroundColor = .clear
        containerView.backgroundColor = .backgroundPurple
        containerView.layer.cornerRadius = 16
        
        iconLabel.isHidden = true
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textAlignment = .left
        subtitleLabel.isHidden = false
        iconImageView.isHidden = false
        favoriteButton.isHidden = false  // Show favorite button in modern style
        
        // Reset constraints
        titleLabel.removeFromSuperview()
        subtitleLabel.removeFromSuperview()
        iconImageView.removeFromSuperview()
        favoriteButton.removeFromSuperview()
        containerView.addSubview(titleLabel)
        containerView.addSubview(subtitleLabel)
        containerView.addSubview(iconImageView)
        containerView.addSubview(favoriteButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: favoriteButton.leadingAnchor, constant: -16),
            
            favoriteButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            favoriteButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            favoriteButton.widthAnchor.constraint(equalToConstant: 44),
            favoriteButton.heightAnchor.constraint(equalToConstant: 44),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            iconImageView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 12),
            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            iconImageView.widthAnchor.constraint(equalToConstant: 24)
        ])
        
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 6
        containerView.layer.shadowOpacity = 0.1
    }
    
    func configure(title: String, icon: String? = nil, systemImage: String? = nil, style: Style = .classic, isFavorite: Bool = false, questionCount: Int? = nil) {
        self.style = style
        
        if style == .classic {
            applyClassicStyle()
            titleLabel.text = title
            if let icon = icon {
                iconLabel.text = icon
                iconLabel.isHidden = false
                iconImageView.isHidden = true
            } else if let systemImage = systemImage {
                iconLabel.isHidden = true
                iconImageView.isHidden = false
                iconImageView.image = UIImage(systemName: systemImage)?.withRenderingMode(.alwaysTemplate)
            }
            if let count = questionCount {
                questionsLabel.text = "\(count) questions"
            }
        } else {
            applyModernStyle()
            titleLabel.text = title
            if let systemImage = systemImage {
                iconImageView.image = UIImage(systemName: systemImage)?.withRenderingMode(.alwaysTemplate)
            }
        }
        
        favoriteButton.setImage(UIImage(systemName: isFavorite ? "heart.fill" : "heart"), for: .normal)
        categoryTitle = title
    }
    
    @objc private func favoriteButtonTapped() {
        onFavoriteButtonTapped?()
    }
    
    func animateIconExit() {
        guard style == .classic else { return }
        
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut) {
            self.iconLabel.transform = CGAffineTransform(translationX: -self.containerView.bounds.width, y: 0)
        } completion: { _ in
            self.iconLabel.transform = .identity
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if style == .modern {
            containerView.layer.shadowPath = UIBezierPath(roundedRect: containerView.bounds, cornerRadius: 16).cgPath
        }
    }
} 
