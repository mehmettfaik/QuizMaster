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
        label.font = .systemFont(ofSize: 48)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .center
        label.textColor = .black
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
        containerView.backgroundColor = .backgroundPurple
        containerView.layer.cornerRadius = 16
        
        iconLabel.isHidden = false
        titleLabel.font = .systemFont(ofSize: 18, weight: .medium)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        subtitleLabel.isHidden = true
        iconImageView.isHidden = true
        favoriteButton.isHidden = true  // Hide favorite button in classic style
        
        // Reset constraints
        iconLabel.removeFromSuperview()
        titleLabel.removeFromSuperview()
        containerView.addSubview(iconLabel)
        containerView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            iconLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            iconLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: -16),
            
            titleLabel.topAnchor.constraint(equalTo: iconLabel.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12)
        ])
        
        // Hafif gölge
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 4
        containerView.layer.shadowOpacity = 0.1
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
    
    func configure(title: String, icon: String? = nil, systemImage: String? = nil, style: Style = .classic, isFavorite: Bool = false) {
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if style == .modern {
            containerView.layer.shadowPath = UIBezierPath(roundedRect: containerView.bounds, cornerRadius: 16).cgPath
        }
    }
} 
