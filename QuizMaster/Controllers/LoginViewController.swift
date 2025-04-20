import UIKit
import Combine
import ObjectiveC

class LoginViewController: UIViewController {
    private let viewModel = AuthViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "quiz_logo")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let welcomeLabel: UILabel = {
        let label = UILabel()
        label.text = "Welcome QuizMaster"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .primaryPurple
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let emailTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "E-posta"
        textField.borderStyle = .roundedRect
        textField.backgroundColor = .white
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.systemGray4.cgColor
        textField.layer.cornerRadius = 8
        textField.autocapitalizationType = .none
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let passwordTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Şifre"
        textField.borderStyle = .roundedRect
        textField.backgroundColor = .white
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.systemGray4.cgColor
        textField.layer.cornerRadius = 8
        textField.isSecureTextEntry = true
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Giriş Yap", for: .normal)
        button.backgroundColor = .primaryPurple
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let registerButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Üye Ol", for: .normal)
        button.backgroundColor = .clear
        button.setTitleColor(.primaryPurple, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.primaryPurple.cgColor
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let googleSignInButton: UIButton = {
        let button = UIButton(type: .system)
        let googleImage = UIImage(named: "google_png")?.withRenderingMode(.alwaysOriginal)
        button.setImage(googleImage, for: .normal)
        button.setTitle("Google ile bağlan", for: .normal)
        button.setTitleColor(UIColor.purple, for: .normal)
        button.backgroundColor = .clear
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        
        // Content layout
        button.contentHorizontalAlignment = .left
        button.imageView?.contentMode = .scaleAspectFit
        
        // Add padding to the left of the image
        let paddingLeft: CGFloat = 8
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: paddingLeft, bottom: 0, right: paddingLeft)
        
        // Space between image and text
        let spacing: CGFloat = 4
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: spacing, bottom: 0, right: -spacing)
        
        // Add border
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.primaryPurple.cgColor
        button.layer.cornerRadius = 8
        
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let dividerLabel: UILabel = {
        let label = UILabel()
        label.text = "veya"
        label.textColor = .gray
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        label.backgroundColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let leftDividerLine: UIView = {
        let view = UIView()
        view.backgroundColor = .gray
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let rightDividerLine: UIView = {
        let view = UIView()
        view.backgroundColor = .gray
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .primaryPurple
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWave()
        setupUI()
        setupBindings()
    }
    
    private func setupWave() {
        let waveLayer = CAShapeLayer()
        let path = UIBezierPath()
        let width = view.bounds.width
        let height: CGFloat = 400

        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: height * 0.7))
        path.addCurve(to: CGPoint(x: width, y: height * 0.7),
                      controlPoint1: CGPoint(x: width * 0.3, y: height),
                      controlPoint2: CGPoint(x: width * 0.7, y: height * 0.4))
        path.addLine(to: CGPoint(x: width, y: 0))
        path.close()

        waveLayer.path = path.cgPath
        waveLayer.fillColor = UIColor.primaryPurple.cgColor

        let waveView = UIView()
        waveView.layer.addSublayer(waveLayer)
        waveView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(waveView)

        NSLayoutConstraint.activate([
            waveView.topAnchor.constraint(equalTo: view.topAnchor),
            waveView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            waveView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            waveView.heightAnchor.constraint(equalToConstant: height)
        ])
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(logoImageView)
        view.addSubview(welcomeLabel)
        view.addSubview(emailTextField)
        view.addSubview(passwordTextField)
        view.addSubview(loginButton)
        view.addSubview(registerButton)
        view.addSubview(leftDividerLine)
        view.addSubview(dividerLabel)
        view.addSubview(rightDividerLine)
        view.addSubview(googleSignInButton)
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 180),
            logoImageView.heightAnchor.constraint(equalToConstant: 180),
            
            welcomeLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 80),
            welcomeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            welcomeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            emailTextField.topAnchor.constraint(equalTo: welcomeLabel.bottomAnchor, constant: 20),
            emailTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            emailTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            emailTextField.heightAnchor.constraint(equalToConstant: 50),
            
            passwordTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 20),
            passwordTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            passwordTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            passwordTextField.heightAnchor.constraint(equalToConstant: 50),
            
            loginButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 30),
            loginButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            loginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            loginButton.heightAnchor.constraint(equalToConstant: 50),
            
            registerButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 20),
            registerButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            registerButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            registerButton.heightAnchor.constraint(equalToConstant: 50),
            
            leftDividerLine.topAnchor.constraint(equalTo: registerButton.bottomAnchor, constant: 30),
            leftDividerLine.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            leftDividerLine.trailingAnchor.constraint(equalTo: dividerLabel.leadingAnchor, constant: -10),
            leftDividerLine.heightAnchor.constraint(equalToConstant: 1),
            
            dividerLabel.centerYAnchor.constraint(equalTo: leftDividerLine.centerYAnchor),
            dividerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dividerLabel.widthAnchor.constraint(equalToConstant: 50),
            
            rightDividerLine.topAnchor.constraint(equalTo: registerButton.bottomAnchor, constant: 30),
            rightDividerLine.leadingAnchor.constraint(equalTo: dividerLabel.trailingAnchor, constant: 10),
            rightDividerLine.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            rightDividerLine.heightAnchor.constraint(equalToConstant: 1),
            
            googleSignInButton.topAnchor.constraint(equalTo: dividerLabel.bottomAnchor, constant: 30),
            googleSignInButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            googleSignInButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            googleSignInButton.heightAnchor.constraint(equalToConstant: 50),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        registerButton.addTarget(self, action: #selector(registerButtonTapped), for: .touchUpInside)
        googleSignInButton.addTarget(self, action: #selector(googleSignInButtonTapped), for: .touchUpInside)
    }
    
    private func setupBindings() {
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.loginButton.isLoading = isLoading
            }
            .store(in: &cancellables)
        
        viewModel.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                if user != nil {
                    let tabBarController = MainTabBarController()
                    if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
                        sceneDelegate.window?.rootViewController = tabBarController
                    }
                }
            }
            .store(in: &cancellables)
        
        viewModel.$error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                if let error = error {
                    self?.showErrorAlert(error)
                }
            }
            .store(in: &cancellables)
    }
    
    @objc private func loginButtonTapped() {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(title: "Error", message: "Please fill in all fields")
            return
        }
        
        guard viewModel.validateEmail(email) else {
            showAlert(title: "Error", message: "Please enter a valid email")
            return
        }
        
        guard viewModel.validatePassword(password) else {
            showAlert(title: "Error", message: LanguageManager.shared.localizedString(for: "password_6_characters"))
            return
        }
        
        viewModel.signIn(email: email, password: password)
    }
    
    @objc private func registerButtonTapped() {
        let registerVC = RegisterViewController()
        registerVC.modalPresentationStyle = .fullScreen
        present(registerVC, animated: true)
    }
    
    @objc private func googleSignInButtonTapped() {
        viewModel.signInWithGoogle(presenting: self)
    }
}
