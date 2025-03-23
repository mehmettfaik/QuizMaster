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
        contentView.layer.masksToBounds = false // Gölgenin görünmesi için false olmalı
        layer.masksToBounds = false // Gölgenin görünmesi için false olmalı
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
        // Reset any existing animations
        iconLabel.layer.removeAllAnimations()
        iconLabel.transform = .identity
        
        // Zoom in animation
        UIView.animate(withDuration: 0.3, animations: {
            self.iconLabel.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        }) { _ in
            // Zoom out animation
            UIView.animate(withDuration: 0.2, animations: {
                self.iconLabel.transform = .identity
            })
        }
    }
    
    private func addBounceAnimation() {
        // Reset any existing animations
        iconLabel.layer.removeAllAnimations()
        iconLabel.transform = .identity
        
        // Initial position - start from above the normal position
        iconLabel.transform = CGAffineTransform(translationX: 0, y: -100)
        
        // First animation - drop with bounce
        UIView.animate(withDuration: 0.7, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1.0, options: [], animations: {
            self.iconLabel.transform = .identity
        }) { _ in
            // Second animation - small continuous bounce
            UIView.animate(withDuration: 0.4, delay: 0, options: [.repeat, .autoreverse], animations: {
                self.iconLabel.transform = CGAffineTransform(translationX: 0, y: 8)
            })
        }
    }
    
    private func addFlipAnimation() {
        // Reset any existing animations
        iconLabel.layer.removeAllAnimations()
        iconLabel.transform = .identity
        
        // Create rotation animation
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.fromValue = 0
        rotationAnimation.toValue = CGFloat.pi * 2  // 360 degrees
        rotationAnimation.duration = 0.6
        rotationAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        // Add animation to layer
        iconLabel.layer.add(rotationAnimation, forKey: "rotationAnimation")
    }
    
    private func addRotateAnimation() {
        // Reset any existing animations
        iconLabel.layer.removeAllAnimations()
        iconLabel.transform = .identity
        
        // First rotate animation
        UIView.animate(withDuration: 0.5, animations: {
            self.iconLabel.transform = CGAffineTransform(rotationAngle: .pi * 1.5)
        }) { _ in
            // Then drop animation
            UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseIn, animations: {
                self.iconLabel.transform = CGAffineTransform(translationX: 0, y: self.containerView.bounds.height)
            }) { _ in
                // Reset position
                self.iconLabel.transform = .identity
            }
        }
    }
    
    private func addPulseAnimation() {
        UIView.animate(withDuration: 1.0, delay: 0, options: [.repeat, .autoreverse], animations: {
            self.iconLabel.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        })
    }
    
    private func addShakeAnimation() {
        // Reset any existing animations
        iconLabel.layer.removeAllAnimations()
        iconLabel.transform = .identity
        
        let shakeAnimation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        shakeAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
        shakeAnimation.duration = 0.6
        shakeAnimation.values = [-5.0, 5.0, -5.0, 5.0, -3.0, 3.0, -1.0, 1.0, 0.0]
        iconLabel.layer.add(shakeAnimation, forKey: "shake")
    }
    
    private func applyModernStyle() {
        backgroundColor = .clear
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 16
        containerView.layer.masksToBounds = false // Gölgenin görünmesi için false olmalı
        
        // Gölge efekti ayarları
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 8
        containerView.layer.shadowOpacity = 0.1
        
        iconLabel.isHidden = true
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .left
        
        subtitleLabel.font = .systemFont(ofSize: 16)
        subtitleLabel.textColor = .systemGray
        subtitleLabel.text = "Easy Medium Hard"
        subtitleLabel.isHidden = false
        
        iconImageView.isHidden = false
        iconImageView.tintColor = .primaryPurple
        iconImageView.contentMode = .scaleAspectFit
        
        favoriteButton.isHidden = false
        favoriteButton.tintColor = .systemRed
        favoriteButton.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        
        // Reset constraints
        titleLabel.removeFromSuperview()
        subtitleLabel.removeFromSuperview()
        iconImageView.removeFromSuperview()
        favoriteButton.removeFromSuperview()
        containerView.addSubview(iconImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(subtitleLabel)
        containerView.addSubview(favoriteButton)
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconImageView.heightAnchor.constraint(equalToConstant: 40),
            iconImageView.widthAnchor.constraint(equalToConstant: 40),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: favoriteButton.leadingAnchor, constant: -16),
            
            subtitleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 16),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.trailingAnchor.constraint(equalTo: favoriteButton.leadingAnchor, constant: -16),
            
            favoriteButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            favoriteButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            favoriteButton.widthAnchor.constraint(equalToConstant: 44),
            favoriteButton.heightAnchor.constraint(equalToConstant: 44)
        ])
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
    
    func triggerSportsAnimation() {
        guard categoryTitle.lowercased() == "sports" else { return }
        addBounceAnimation()
    }
    
    func triggerArtAnimation() {
        guard categoryTitle.lowercased() == "art" else { return }
        addRotateAnimation()
    }
    
    func triggerShakeAnimation() {
        guard categoryTitle == "Diğer" else { return }
        addShakeAnimation()
    }
    
    func triggerScienceAnimation() {
        guard categoryTitle.lowercased() == "science" else { return }
        addBubbleAnimation()
    }
    
    func triggerHistoryAnimation() {
        guard categoryTitle.lowercased() == "history" else { return }
        addFlipAnimation()
    }
    
    //override func layoutSubviews() {
      //  super.layoutSubviews()
        //if style == .classic {
          //  containerView.layer.shadowPath = UIBezierPath(roundedRect: containerView.bounds, cornerRadius: 16).cgPath
        //}
  //  }
}
