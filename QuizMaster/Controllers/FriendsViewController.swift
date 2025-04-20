import UIKit
import FirebaseFirestore
import FirebaseAuth

class FriendsViewController: UIViewController {
    private let segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: [
            LanguageManager.shared.localizedString(for: "add_friend"),
            LanguageManager.shared.localizedString(for: "friend_requests"),])
        control.selectedSegmentIndex = 0
        control.backgroundColor = .secondaryPurple.withAlphaComponent(0.1)
        control.selectedSegmentTintColor = .primaryPurple
        control.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .normal)
        control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = LanguageManager.shared.localizedString(for: "search_by_email")
        searchBar.searchBarStyle = .minimal
        searchBar.searchTextField.backgroundColor = .white
        searchBar.searchTextField.autocapitalizationType = .none // İlk harfi küçük başlat
        searchBar.layer.cornerRadius = 12
        searchBar.clipsToBounds = true
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        return searchBar
    }()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.register(FriendUserCell.self, forCellReuseIdentifier: FriendUserCell.identifier)
        table.register(FriendRequestCell.self, forCellReuseIdentifier: FriendRequestCell.identifier)
        table.backgroundColor = .clear
        table.separatorStyle = .none
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = LanguageManager.shared.localizedString(for: "no_results_yet")
        label.textColor = .gray
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var users: [FriendUser] = []
    private var friendRequests: [FriendRequest] = []
    private var pendingRequestIds: Set<String> = []
    private var friendIds: Set<String> = []
    private let db = Firestore.firestore()
    
    private var tableViewTopConstraint: NSLayoutConstraint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDelegates()
        setupNavigationBar()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.98, alpha: 1.0)
        title = LanguageManager.shared.localizedString(for: "my_friends")
        
        view.addSubview(segmentedControl)
        view.addSubview(searchBar)
        view.addSubview(tableView)
        view.addSubview(emptyStateLabel)
        
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            segmentedControl.heightAnchor.constraint(equalToConstant: 40),
            
            searchBar.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 8),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor)
        ])
        
        updateTableViewTopConstraint()
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
    }
    
    private func updateTableViewTopConstraint() {
        tableViewTopConstraint?.isActive = false
        
        if segmentedControl.selectedSegmentIndex == 0 {
            // Arkadaş Ekle sekmesinde SearchBar ile TableView arasında 8pt boşluk
            tableViewTopConstraint = tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8)
        } else {
            // İstekler sekmesinde SegmentedControl ile TableView arasında 8pt boşluk
            tableViewTopConstraint = tableView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 12)
        }
        tableViewTopConstraint?.isActive = true
    }
    
    private func setupDelegates() {
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func setupNavigationBar() {
        let backButton = UIBarButtonItem(image: UIImage(systemName: "chevron.left"),
                                       style: .plain,
                                       target: self,
                                       action: #selector(backButtonTapped))
        backButton.tintColor = .primaryPurple
        navigationItem.leftBarButtonItem = backButton
        
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.black,
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
    }
    
    @objc private func segmentChanged() {
        searchBar.isHidden = segmentedControl.selectedSegmentIndex == 1
        updateTableViewTopConstraint() // Constraint'i güncelle
        
        if segmentedControl.selectedSegmentIndex == 1 {
            loadFriendRequests()
        } else {
            users.removeAll()
            tableView.reloadData()
        }
        
        // Animasyonlu geçiş
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc private func backButtonTapped() {
        dismiss(animated: true)
    }
    
    private func searchUsers(with prefix: String) {
        guard !prefix.isEmpty else {
            users.removeAll()
            tableView.reloadData()
            return
        }
        
        guard let currentUser = Auth.auth().currentUser else { return }
        
        let endPrefix = prefix + "\u{f8ff}"
        db.collection("users")
            .whereField("email", isGreaterThanOrEqualTo: prefix)
            .whereField("email", isLessThan: endPrefix)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else { return }
                
                self.users = documents.compactMap { document -> FriendUser? in
                    // Mevcut kullanıcıyı sonuçlardan çıkar
                    guard document.documentID != currentUser.uid else { return nil }
                    
                    let data = document.data()
                    guard let email = data["email"] as? String,
                          let name = data["name"] as? String else { return nil }
                    let avatar = data["avatar"] as? String ?? "wizard"
                    return FriendUser(id: document.documentID, email: email, name: name, avatar: avatar)
                }
                
                // Kullanıcıların arkadaşlık durumlarını kontrol et
                self.checkFriendshipStatus()
                
                // Boş durum kontrolü
                self.updateEmptyState()
            }
    }
    
    private func checkFriendshipStatus() {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        // Arkadaşları kontrol et
        db.collection("users").document(currentUser.uid).getDocument { [weak self] snapshot, error in
            guard let self = self,
                  let data = snapshot?.data(),
                  let friends = data["friends"] as? [String] else {
                self?.checkPendingRequests()
                return
            }
            
            self.friendIds = Set(friends)
            self.checkPendingRequests()
        }
    }
    
    private func checkPendingRequests() {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        pendingRequestIds.removeAll()
        
        let userIds = users.map { $0.id }
        guard !userIds.isEmpty else {
            self.tableView.reloadData()
            return
        }
        
        // Sadece arkadaş olmayan kullanıcılar için istek kontrolü yap
        let nonFriendUserIds = userIds.filter { !friendIds.contains($0) }
        guard !nonFriendUserIds.isEmpty else {
            self.tableView.reloadData()
            return
        }
        
        db.collection("friendRequests")
            .whereField("senderId", isEqualTo: currentUser.uid)
            .whereField("receiverId", in: nonFriendUserIds)
            .whereField("status", isEqualTo: "pending")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else {
                    self?.tableView.reloadData()
                    return
                }
                
                documents.forEach { document in
                    if let receiverId = document.data()["receiverId"] as? String {
                        self.pendingRequestIds.insert(receiverId)
                    }
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
    }
    
    private func loadFriendRequests() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("friendRequests")
            .whereField("receiverId", isEqualTo: currentUserId)
            .whereField("status", isEqualTo: "pending")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else { return }
                
                self.friendRequests = documents.compactMap { document -> FriendRequest? in
                    let data = document.data()
                    guard let senderId = data["senderId"] as? String,
                          let senderEmail = data["senderEmail"] as? String,
                          let status = data["status"] as? String else { return nil }
                    return FriendRequest(id: document.documentID, senderId: senderId, senderEmail: senderEmail, status: status)
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
    }
    
    private func sendFriendRequest(to user: FriendUser) {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        guard user.id != currentUser.uid else {
            showAlert(
                title: LanguageManager.shared.localizedString(for: "error_title"),
                message: LanguageManager.shared.localizedString(for: "cant_send_request_to_self")
            )
            return
        }
        
        let requestData: [String: Any] = [
            "senderId": currentUser.uid,
            "senderEmail": currentUser.email ?? "",
            "receiverId": user.id,
            "receiverEmail": user.email,
            "status": "pending",
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        db.collection("friendRequests").addDocument(data: requestData) { [weak self] error in
            if let error = error {
                print("Error sending friend request: \(error)")
            } else {
                DispatchQueue.main.async {
                    self?.showAlert(
                        title: LanguageManager.shared.localizedString(for: "success_title"),
                        message: LanguageManager.shared.localizedString(for: "friend_request_sent_success")
                    )
                }
            }
        }
    }
    
    private func handleFriendRequest(_ request: FriendRequest, accepted: Bool) {
        db.collection("friendRequests").document(request.id).updateData([
            "status": accepted ? "accepted" : "rejected"
        ]) { [weak self] error in
            if let error = error {
                print("Error updating friend request: \(error)")
            } else {
                if accepted {
                    self?.addFriendToUsersList(request)
                }
                self?.loadFriendRequests()
            }
        }
    }
    
    private func addFriendToUsersList(_ request: FriendRequest) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Add to current user's friends list
        db.collection("users").document(currentUserId).updateData([
            "friends": FieldValue.arrayUnion([request.senderId])
        ])
        
        // Add to sender's friends list
        db.collection("users").document(request.senderId).updateData([
            "friends": FieldValue.arrayUnion([currentUserId])
        ])
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(
            title: LanguageManager.shared.localizedString(for: "ok_button"),
            style: .default
        ))
        present(alert, animated: true)
    }
}

extension FriendsViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchUsers(with: searchText)
    }
}

extension FriendsViewController: FriendRequestCellDelegate {
    func didTapAccept(for request: FriendRequest) {
        handleFriendRequest(request, accepted: true)
    }
    
    func didTapReject(for request: FriendRequest) {
        handleFriendRequest(request, accepted: false)
    }
}

extension FriendsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return segmentedControl.selectedSegmentIndex == 0 ? users.count : friendRequests.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if segmentedControl.selectedSegmentIndex == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: FriendUserCell.identifier, for: indexPath) as! FriendUserCell
            let user = users[indexPath.row]
            cell.configure(with: user,
                         hasRequestPending: pendingRequestIds.contains(user.id),
                         isFriend: friendIds.contains(user.id))
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: FriendRequestCell.identifier, for: indexPath) as! FriendRequestCell
            let request = friendRequests[indexPath.row]
            cell.delegate = self // Delegate'i atıyoruz
            cell.configure(with: request)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Sadece Arkadaş Ekle sekmesinde uyarı göster
        if segmentedControl.selectedSegmentIndex == 0 {
            let user = users[indexPath.row]
            
            // Eğer zaten arkadaşsa veya istek beklemedeyse, işlem yapma
            guard !friendIds.contains(user.id) && !pendingRequestIds.contains(user.id) else {
                return
            }
            
            let alert = UIAlertController(
                title: LanguageManager.shared.localizedString(for: "friend_request"),
                message: String(format: LanguageManager.shared.localizedString(for: "send_friend_request_confirmation"), user.name),
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(
                title: LanguageManager.shared.localizedString(for: "cancel_button"),
                style: .cancel
            ))
            alert.addAction(UIAlertAction(
                title: LanguageManager.shared.localizedString(for: "send_button"),
                style: .default
            ) { [weak self] _ in
                self?.sendFriendRequest(to: user)
            })
            
            present(alert, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return segmentedControl.selectedSegmentIndex == 0 ? 90 : 70
    }
    
    private func updateEmptyState() {
        if segmentedControl.selectedSegmentIndex == 0 {
            emptyStateLabel.isHidden = !users.isEmpty
            emptyStateLabel.text = LanguageManager.shared.localizedString(for: "no_search_results_found")
        } else {
            emptyStateLabel.isHidden = !friendRequests.isEmpty
            emptyStateLabel.text = LanguageManager.shared.localizedString(for: "no_pending_requests_found")
        }
    }
} 
