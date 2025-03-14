import UIKit
import FirebaseFirestore

class SearchViewController: UIViewController {
    private let quizListViewModel = QuizListViewModel()
    
    private let categories: [(title: String, icon: String)] = [
        ("Vehicle", "car.fill"),
        ("Science", "atom"),
        ("Sports", "sportscourt.fill"),
        ("History", "book.fill"),
        ("Art", "paintpalette.fill"),
        ("Celebrity", "star.fill"),
        ("Video Games", "gamecontroller.fill"),
        ("General Culture", "globe"),
        ("Animals", "pawprint.fill"),
        ("Computer Science", "desktopcomputer"),
        ("Mathematics", "function"),
        ("Mythology", "building.columns.fill")
    ]
    
    private var favoriteCategories: Set<String> = Set()
    private var filteredCategories: [(title: String, icon: String)] = []
    private var isSearching: Bool = false
    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search..."
        searchBar.searchBarStyle = .minimal
        searchBar.backgroundColor = .white
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        return searchBar
    }()
  
    
    public let segmentedControl: UISegmentedControl = {
        let items = ["Categories", "Favorites", "Top Quiz"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.selectedSegmentTintColor = .primaryPurple
        control.backgroundColor = .white
        control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        control.setTitleTextAttributes([.foregroundColor: UIColor.primaryPurple], for: .normal)
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
        collectionView.backgroundColor = .white
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
        setupSearchBar()
        setupViewModel()
        setupSegmentedControl()
        
        // Başlangıçta tüm kategorileri göster
        filteredCategories = categories
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(searchBar)
        view.addSubview(segmentedControl)
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            segmentedControl.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 16),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            collectionView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
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
                quizListViewModel.fetchQuizzes(searchText: searchText)
                filteredCategories = []
            default:
                filteredCategories = []
            }
            isSearching = false
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
                quizListViewModel.fetchQuizzes(searchText: searchText)
                filteredCategories = []
            default:
                filteredCategories = []
            }
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
        if segmentedControl.selectedSegmentIndex == 0 || segmentedControl.selectedSegmentIndex == 1 {
            return filteredCategories.isEmpty && isSearching ? 1 : filteredCategories.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CategoryCell", for: indexPath) as! CategoryCell
        
        if segmentedControl.selectedSegmentIndex == 0 || segmentedControl.selectedSegmentIndex == 1 {
            if filteredCategories.isEmpty && isSearching {
                cell.configure(title: "No results found", systemImage: "xmark.circle.fill", style: .modern)
            } else {
                let category = filteredCategories[indexPath.item]
                let isFavorite = favoriteCategories.contains(category.title)
                cell.configure(title: category.title, systemImage: category.icon, style: .modern, isFavorite: isFavorite)
                
                cell.onFavoriteButtonTapped = { [weak self] in
                    self?.toggleFavorite(for: category.title)
                }
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width - 32 // Full width minus padding
        return CGSize(width: width, height: 120) // Daha yüksek bir hücre
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if !filteredCategories.isEmpty {
            let category = filteredCategories[indexPath.item]
            let difficultyVC = DifficultyViewController(category: category.title)
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
 


