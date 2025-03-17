import UIKit
import FirebaseFirestore

class AddQuestionViewController: UIViewController {
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .primaryPurple
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        let image = UIImage(systemName: "xmark", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Add New Question"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let formContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 20
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let categoryLabel: UILabel = {
        let label = UILabel()
        label.text = "Category"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let categoryPicker: UIPickerView = {
        let picker = UIPickerView()
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()
    
    private let difficultyLabel: UILabel = {
        let label = UILabel()
        label.text = "Difficulty"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let difficultySegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["Easy", "Medium", "Hard"])
        control.selectedSegmentIndex = 0
        control.selectedSegmentTintColor = .primaryPurple
        let titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        control.setTitleTextAttributes(titleTextAttributes, for: .selected)
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private let questionLabel: UILabel = {
        let label = UILabel()
        label.text = "Question"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let questionTextView: UITextView = {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 16)
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 12
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    private let optionsLabel: UILabel = {
        let label = UILabel()
        label.text = "Options"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let optionsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Save Question", for: .normal)
        button.backgroundColor = .primaryPurple
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Add shadow
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.1
        
        return button
    }()
    
    private class OptionView: UIView {
        let textField: UITextField
        let checkmarkButton: UIButton
        var isSelected: Bool = false {
            didSet {
                updateCheckmarkState()
            }
        }
        
        init(index: Int) {
            textField = UITextField()
            textField.placeholder = "Option \(index + 1)"
            textField.borderStyle = .none
            textField.backgroundColor = .systemGray6
            textField.layer.cornerRadius = 12
            textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
            textField.leftViewMode = .always
            
            checkmarkButton = UIButton(type: .system)
            let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
            let image = UIImage(systemName: "checkmark.circle", withConfiguration: config)
            checkmarkButton.setImage(image, for: .normal)
            checkmarkButton.tintColor = .systemGray3
            
            super.init(frame: .zero)
            
            addSubview(textField)
            addSubview(checkmarkButton)
            
            textField.translatesAutoresizingMaskIntoConstraints = false
            checkmarkButton.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                textField.leadingAnchor.constraint(equalTo: leadingAnchor),
                textField.topAnchor.constraint(equalTo: topAnchor),
                textField.bottomAnchor.constraint(equalTo: bottomAnchor),
                textField.trailingAnchor.constraint(equalTo: checkmarkButton.leadingAnchor, constant: -8),
                
                checkmarkButton.trailingAnchor.constraint(equalTo: trailingAnchor),
                checkmarkButton.centerYAnchor.constraint(equalTo: centerYAnchor),
                checkmarkButton.widthAnchor.constraint(equalToConstant: 44),
                checkmarkButton.heightAnchor.constraint(equalToConstant: 44),
                
                heightAnchor.constraint(equalToConstant: 44)
            ])
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func updateCheckmarkState() {
            let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
            let image = UIImage(systemName: isSelected ? "checkmark.circle.fill" : "checkmark.circle", withConfiguration: config)
            checkmarkButton.setImage(image, for: .normal)
            checkmarkButton.tintColor = isSelected ? .primaryPurple : .systemGray3
        }
    }
    
    private var optionViews: [OptionView] = []
    private let categories = QuizCategory.allCases.sorted { $0.rawValue < $1.rawValue }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDelegates()
        setupActions()
    }
    
    private func setupUI() {
        view.backgroundColor = .primaryPurple
        
        view.addSubview(headerView)
        headerView.addSubview(closeButton)
        headerView.addSubview(titleLabel)
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(formContainerView)
        formContainerView.addSubview(categoryLabel)
        formContainerView.addSubview(categoryPicker)
        formContainerView.addSubview(difficultyLabel)
        formContainerView.addSubview(difficultySegmentedControl)
        formContainerView.addSubview(questionLabel)
        formContainerView.addSubview(questionTextView)
        formContainerView.addSubview(optionsLabel)
        formContainerView.addSubview(optionsStackView)
        formContainerView.addSubview(saveButton)
        
        // Add 4 option views
        for i in 0..<4 {
            let optionView = OptionView(index: i)
            optionView.checkmarkButton.addTarget(self, action: #selector(checkmarkButtonTapped(_:)), for: .touchUpInside)
            optionViews.append(optionView)
            optionsStackView.addArrangedSubview(optionView)
        }
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 60),
            
            closeButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            closeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
            
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            formContainerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            formContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            formContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            formContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            categoryLabel.topAnchor.constraint(equalTo: formContainerView.topAnchor, constant: 24),
            categoryLabel.leadingAnchor.constraint(equalTo: formContainerView.leadingAnchor, constant: 20),
            
            categoryPicker.topAnchor.constraint(equalTo: categoryLabel.bottomAnchor, constant: 8),
            categoryPicker.leadingAnchor.constraint(equalTo: formContainerView.leadingAnchor, constant: 20),
            categoryPicker.trailingAnchor.constraint(equalTo: formContainerView.trailingAnchor, constant: -20),
            categoryPicker.heightAnchor.constraint(equalToConstant: 120),
            
            difficultyLabel.topAnchor.constraint(equalTo: categoryPicker.bottomAnchor, constant: 20),
            difficultyLabel.leadingAnchor.constraint(equalTo: formContainerView.leadingAnchor, constant: 20),
            
            difficultySegmentedControl.topAnchor.constraint(equalTo: difficultyLabel.bottomAnchor, constant: 8),
            difficultySegmentedControl.leadingAnchor.constraint(equalTo: formContainerView.leadingAnchor, constant: 20),
            difficultySegmentedControl.trailingAnchor.constraint(equalTo: formContainerView.trailingAnchor, constant: -20),
            
            questionLabel.topAnchor.constraint(equalTo: difficultySegmentedControl.bottomAnchor, constant: 20),
            questionLabel.leadingAnchor.constraint(equalTo: formContainerView.leadingAnchor, constant: 20),
            
            questionTextView.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: 8),
            questionTextView.leadingAnchor.constraint(equalTo: formContainerView.leadingAnchor, constant: 20),
            questionTextView.trailingAnchor.constraint(equalTo: formContainerView.trailingAnchor, constant: -20),
            questionTextView.heightAnchor.constraint(equalToConstant: 120),
            
            optionsLabel.topAnchor.constraint(equalTo: questionTextView.bottomAnchor, constant: 20),
            optionsLabel.leadingAnchor.constraint(equalTo: formContainerView.leadingAnchor, constant: 20),
            
            optionsStackView.topAnchor.constraint(equalTo: optionsLabel.bottomAnchor, constant: 8),
            optionsStackView.leadingAnchor.constraint(equalTo: formContainerView.leadingAnchor, constant: 20),
            optionsStackView.trailingAnchor.constraint(equalTo: formContainerView.trailingAnchor, constant: -20),
            
            saveButton.topAnchor.constraint(equalTo: optionsStackView.bottomAnchor, constant: 30),
            saveButton.leadingAnchor.constraint(equalTo: formContainerView.leadingAnchor, constant: 20),
            saveButton.trailingAnchor.constraint(equalTo: formContainerView.trailingAnchor, constant: -20),
            saveButton.heightAnchor.constraint(equalToConstant: 50),
            saveButton.bottomAnchor.constraint(equalTo: formContainerView.bottomAnchor, constant: -30)
        ])
    }
    
    private func setupDelegates() {
        categoryPicker.delegate = self
        categoryPicker.dataSource = self
    }
    
    private func setupActions() {
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
    }
    
    @objc private func closeButtonTapped() {
        if let tabBarController = presentingViewController as? UITabBarController {
            // Önce ana sayfaya geç
            tabBarController.selectedIndex = 0
            // Sonra ekranı kapat
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.dismiss(animated: true)
            }
        } else {
            dismiss(animated: true)
        }
    }
    
    @objc private func checkmarkButtonTapped(_ sender: UIButton) {
        // Find the tapped option view
        if let tappedView = sender.superview as? OptionView {
            // Deselect all other options
            optionViews.forEach { $0.isSelected = false }
            // Select the tapped option
            tappedView.isSelected = true
        }
    }
    
    @objc private func saveButtonTapped() {
        // Show loading state
        saveButton.isEnabled = false
        saveButton.setTitle("Saving...", for: .normal)
        
        // Validate inputs
        guard let question = questionTextView.text, !question.isEmpty,
              let selectedCategory = categories[safe: categoryPicker.selectedRow(inComponent: 0)]?.rawValue else {
            presentAlert(title: "Error", message: "Please fill in all fields")
            saveButton.isEnabled = true
            saveButton.setTitle("Save Question", for: .normal)
            return
        }
        
        let options = optionViews.compactMap { $0.textField.text }.filter { !$0.isEmpty }
        guard options.count == 4 else {
            presentAlert(title: "Error", message: "Please fill in all options")
            saveButton.isEnabled = true
            saveButton.setTitle("Save Question", for: .normal)
            return
        }
        
        // Get the selected correct answer
        guard let selectedIndex = optionViews.firstIndex(where: { $0.isSelected }),
              let correctAnswer = options[safe: selectedIndex] else {
            presentAlert(title: "Error", message: "Please select the correct answer")
            saveButton.isEnabled = true
            saveButton.setTitle("Save Question", for: .normal)
            return
        }
        
        let difficulty = QuizDifficulty.allCases[difficultySegmentedControl.selectedSegmentIndex]
        
        // Create question document
        let db = Firestore.firestore()
        let questionData: [String: Any] = [
            "question": question,
            "options": options,
            "correct_answer": correctAnswer,
            "difficulty": difficulty.rawValue.lowercased(),
            "created_at": Timestamp()
        ]
        
        db.collection("aaaa")
            .document(selectedCategory.lowercased())
            .collection("questions")
            .addDocument(data: questionData) { [weak self] error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.presentAlert(title: "Error", message: error.localizedDescription)
                        self?.saveButton.isEnabled = true
                        self?.saveButton.setTitle("Save Question", for: .normal)
                    } else {
                        self?.presentAlert(title: "Success", message: "Question added successfully") { _ in
                            if let tabBarController = self?.presentingViewController as? UITabBarController {
                                // Önce ana sayfaya geç
                                tabBarController.selectedIndex = 0
                                // Sonra ekranı kapat
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    self?.dismiss(animated: true)
                                }
                            } else {
                                self?.dismiss(animated: true)
                            }
                        }
                    }
                }
            }
    }
    
    private func presentAlert(title: String, message: String, completion: ((UIAlertAction) -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: completion))
        present(alert, animated: true)
    }
}

extension AddQuestionViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return categories.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return categories[row].rawValue
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
} 
