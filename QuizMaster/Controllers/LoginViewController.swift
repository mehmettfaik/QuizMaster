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
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Quiz Master"
        label.font = .systemFont(ofSize: 32, weight: .bold)
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
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let googleSignInButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Google ile Giriş Yap", for: .normal)
        button.setImage(UIImage(named: "google_logo")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.backgroundColor = .white
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemGray4.cgColor
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 0)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .primaryPurple
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private let decorationImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "quiz_decoration")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(decorationImageView)
        view.addSubview(logoImageView)
        view.addSubview(titleLabel)
        view.addSubview(emailTextField)
        view.addSubview(passwordTextField)
        view.addSubview(loginButton)
        view.addSubview(registerButton)
        view.addSubview(googleSignInButton)
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            decorationImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            decorationImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            decorationImageView.widthAnchor.constraint(equalTo: view.widthAnchor),
            decorationImageView.heightAnchor.constraint(equalToConstant: 200),
            
            logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 200),
            logoImageView.heightAnchor.constraint(equalToConstant: 200),
            
            titleLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 40),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            emailTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
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
            registerButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            googleSignInButton.topAnchor.constraint(equalTo: registerButton.bottomAnchor, constant: 30),
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
            showAlert(title: "Error", message: "Password must be at least 6 characters")
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
