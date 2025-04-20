import UIKit
import FirebaseFirestore

class SearchViewController: UIViewController {
    private let quizListViewModel = QuizListViewModel()
    
    private let categories: [(title: String, icon: String)] = [
        (LanguageManager.shared.localizedString(for: "vehicle"), "car.fill"),
        (LanguageManager.shared.localizedString(for: "science"), "atom"),
        (LanguageManager.shared.localizedString(for: "sports"), "sportscourt.fill"),
        (LanguageManager.shared.localizedString(for: "history"), "book.fill"),
        (LanguageManager.shared.localizedString(for: "art"), "paintpalette.fill"),
        (LanguageManager.shared.localizedString(for: "celebrity"), "star.fill"),
        (LanguageManager.shared.localizedString(for: "video_games"), "gamecontroller.fill"),
        (LanguageManager.shared.localizedString(for: "general_culture"), "globe"),
        (LanguageManager.shared.localizedString(for: "animals"), "pawprint.fill"),
        (LanguageManager.shared.localizedString(for: "computer_science"), "desktopcomputer"),
        (LanguageManager.shared.localizedString(for: "mathematics"), "function"),
        (LanguageManager.shared.localizedString(for: "mythology"), "building.columns.fill")
    ]
    
    private var favoriteCategories: Set<String> = Set()
    private var filteredCategories: [(title: String, icon: String)] = []
    private var isSearching: Bool = false
    
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .primaryPurple
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = LanguageManager.shared.localizedString(for: "search")
        searchBar.searchBarStyle = .minimal
        searchBar.backgroundColor = .clear
        searchBar.searchTextField.backgroundColor = .white
        searchBar.searchTextField.layer.cornerRadius = 10
        searchBar.searchTextField.clipsToBounds = true
        searchBar.tintColor = .primaryPurple
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        return searchBar
    }()
    
    public let segmentedControl: UISegmentedControl = {
        let items = [
            LanguageManager.shared.localizedString(for: "categories"),
            LanguageManager.shared.localizedString(for: "favorites"),
            LanguageManager.shared.localizedString(for: "top_quiz")
        ]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.selectedSegmentTintColor = .white
        control.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        control.setTitleTextAttributes([
            .foregroundColor: UIColor.white.withAlphaComponent(0.7)
        ], for: .normal)
        control.setTitleTextAttributes([
            .foregroundColor: UIColor.primaryPurple,
            .font: UIFont.systemFont(ofSize: 14, weight: .semibold)
        ], for: .selected)
        control.layer.cornerRadius = 8
        control.clipsToBounds = true
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    private let noResultsLabel: UILabel = {
        let label = UILabel()
        label.text = LanguageManager.shared.localizedString(for: "no_results")
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textColor = .gray
        label.textAlignment = .center
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let topQuizCategories = [
        (LanguageManager.shared.localizedString(for: "computer_science"), "desktopcomputer"),
        (LanguageManager.shared.localizedString(for: "general_culture"), "globe"),
        (LanguageManager.shared.localizedString(for: "art"), "paintpalette.fill"),
        (LanguageManager.shared.localizedString(for: "celebrity"), "star.fill")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
        setupSearchBar()
        setupViewModel()
        setupSegmentedControl()
        
        filteredCategories = categories
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(headerView)
        headerView.addSubview(searchBar)
        headerView.addSubview(segmentedControl)
        view.addSubview(collectionView)
        view.addSubview(noResultsLabel)
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 180),
            
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchBar.heightAnchor.constraint(equalToConstant: 44),
            
            segmentedControl.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 16),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            segmentedControl.heightAnchor.constraint(equalToConstant: 40),
            
            collectionView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            noResultsLabel.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor),
            noResultsLabel.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor)
        ])
    }
    
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(CategoryCell.self, forCellWithReuseIdentifier: "CategoryCell")
    }
    
    private func setupSearchBar() {
        searchBar.delegate = self
    }
    
    private func setupViewModel() {
        quizListViewModel.onQuizzesUpdated = { [weak self] in
            DispatchQueue.main.async {
                self?.collectionView.reloadData()
            }
        }
        
        quizListViewModel.onError = { [weak self] error in
            print("Error fetching quizzes: \(error.localizedDescription)")
            if let self = self {
                self.showErrorAlert(error)
            }
        }
        
        // Load favorite categories from UserDefaults
        if let savedFavorites = UserDefaults.standard.array(forKey: "FavoriteCategories") as? [String] {
            favoriteCategories = Set(savedFavorites)
        }
    }
    
    private func setupSegmentedControl() {
        segmentedControl.addTarget(self, action: #selector(segmentedControlValueChanged), for: .valueChanged)
    }
    
    private func filterCategories(with searchText: String) {
        if searchText.isEmpty {
            switch segmentedControl.selectedSegmentIndex {
            case 0: // Categories
                filteredCategories = categories
            case 1: // Favorites
                filteredCategories = categories.filter { favoriteCategories.contains($0.title) }
            case 2: // Top Quiz
                filteredCategories = topQuizCategories
            default:
                filteredCategories = []
            }
            isSearching = false
            noResultsLabel.isHidden = true
        } else {
            isSearching = true
            switch segmentedControl.selectedSegmentIndex {
            case 0: // Categories
                filteredCategories = categories.filter { category in
                    category.title.lowercased().contains(searchText.lowercased())
                }
            case 1: // Favorites
                filteredCategories = categories.filter { category in
                    favoriteCategories.contains(category.title) &&
                    category.title.lowercased().contains(searchText.lowercased())
                }
            case 2: // Top Quiz
                filteredCategories = topQuizCategories.filter { category in
                    category.0.lowercased().contains(searchText.lowercased())
                }
            default:
                filteredCategories = []
            }
            noResultsLabel.isHidden = !filteredCategories.isEmpty
        }
        collectionView.reloadData()
    }
    
    @objc public func segmentedControlValueChanged() {
        // Segment değiştiğinde mevcut search text'i kullanarak filtrele
        let currentSearchText = searchBar.text ?? ""
        filterCategories(with: currentSearchText)
    }
    
    private func toggleFavorite(for category: String) {
        if favoriteCategories.contains(category) {
            favoriteCategories.remove(category)
        } else {
            favoriteCategories.insert(category)
        }
        
        // Save to UserDefaults
        UserDefaults.standard.set(Array(favoriteCategories), forKey: "FavoriteCategories")
        
        // Reload collection view if we're in favorites tab
        if segmentedControl.selectedSegmentIndex == 1 {
            segmentedControlValueChanged()
        } else {
            collectionView.reloadData()
        }
    }
}

extension SearchViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredCategories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CategoryCell", for: indexPath) as! CategoryCell
        
        let category = filteredCategories[indexPath.item]
        let isFavorite = favoriteCategories.contains(category.0)
        
        if segmentedControl.selectedSegmentIndex == 2 {
            // Top Quiz için
            cell.configure(title: category.0, systemImage: category.1, style: .modern, isFavorite: isFavorite)
        } else {
            // Categories ve Favorites için
            cell.configure(title: category.title, systemImage: category.icon, style: .modern, isFavorite: isFavorite)
        }
        
        cell.onFavoriteButtonTapped = { [weak self] in
            if self?.segmentedControl.selectedSegmentIndex == 2 {
                self?.toggleFavorite(for: category.0)
            } else {
                self?.toggleFavorite(for: category.title)
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width - 32 // Full width minus padding
        return CGSize(width: width, height: 120)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if !filteredCategories.isEmpty {
            let category: String
            if segmentedControl.selectedSegmentIndex == 2 {
                category = filteredCategories[indexPath.item].0
            } else {
                category = filteredCategories[indexPath.item].title
            }
            
            let difficultyVC = DifficultyViewController(category: category)
            difficultyVC.modalPresentationStyle = .fullScreen
            present(difficultyVC, animated: true)
        }
    }
}

extension SearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterCategories(with: searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
} 
 


