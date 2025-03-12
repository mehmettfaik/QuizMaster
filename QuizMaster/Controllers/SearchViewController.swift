import UIKit
import FirebaseFirestore

class SearchViewController: UIViewController {
    private let quizListViewModel = QuizListViewModel()
    
    private let categories: [(title: String, icon: String)] = [
        ("Vehicle", "🚗"),
        ("Science", "🔬"),
        ("Sports", "⚽️"),
        ("History", "📚"),
        ("Art", "🎨"),
        ("Celebrity", "⭐️")
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
        let items = ["Favorite", "Quiz", "Categories", "Friends"]
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
        }
        
        // Load favorite categories from UserDefaults
        if let savedFavorites = UserDefaults.standard.array(forKey: "FavoriteCategories") as? [String] {
            favoriteCategories = Set(savedFavorites)
        }
    }
    
    private func setupSegmentedControl() {
        segmentedControl.addTarget(self, action: #selector(segmentedControlValueChanged), for: .valueChanged)
    }
    
    @objc public func segmentedControlValueChanged() {
        searchBar.text = ""
        isSearching = false
        
        switch segmentedControl.selectedSegmentIndex {
        case 0: // Favorites
            filteredCategories = categories.filter { favoriteCategories.contains($0.title) }
        case 2: // Categories
            filteredCategories = categories
        default:
            filteredCategories = []
        }
        
        collectionView.reloadData()
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
        if segmentedControl.selectedSegmentIndex == 0 {
            segmentedControlValueChanged()
        } else {
            collectionView.reloadData()
        }
    }
    
    private func filterCategories(with searchText: String) {
        if searchText.isEmpty {
            filteredCategories = categories
            isSearching = false
        } else {
            isSearching = true
            filteredCategories = categories.filter {
                $0.title.lowercased().contains(searchText.lowercased())
            }
        }
        collectionView.reloadData()
    }
}

extension SearchViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if segmentedControl.selectedSegmentIndex == 2 || segmentedControl.selectedSegmentIndex == 0 {
            return filteredCategories.isEmpty && isSearching ? 1 : filteredCategories.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CategoryCell", for: indexPath) as! CategoryCell
        
        if segmentedControl.selectedSegmentIndex == 2 || segmentedControl.selectedSegmentIndex == 0 {
            if filteredCategories.isEmpty && isSearching {
                cell.configure(title: "No results found", icon: "❌", style: .modern)
            } else {
                let category = filteredCategories[indexPath.item]
                let isFavorite = favoriteCategories.contains(category.title)
                cell.configure(title: category.title, icon: category.icon, style: .modern, isFavorite: isFavorite)
                
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
        switch segmentedControl.selectedSegmentIndex {
        case 1: // Quiz
            quizListViewModel.fetchQuizzes(searchText: searchText)
        case 2: // Categories
            filterCategories(with: searchText)
        default:
            break
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
} 
 


