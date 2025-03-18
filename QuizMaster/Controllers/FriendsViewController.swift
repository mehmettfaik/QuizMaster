import UIKit
import FirebaseFirestore
import FirebaseAuth

class FriendsViewController: UIViewController {
    private let segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["Arkadaş Ekle", "İstekler"])
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
        searchBar.placeholder = "Email ile ara..."
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
        label.text = "Henüz bir sonuç yok"
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDelegates()
        setupNavigationBar()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.98, alpha: 1.0)
        title = "Arkadaşlar"
        
        view.addSubview(segmentedControl)
        view.addSubview(searchBar)
        view.addSubview(tableView)
        view.addSubview(emptyStateLabel)
        
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            segmentedControl.heightAnchor.constraint(equalToConstant: 40),
            
            searchBar.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 12),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor)
        ])
        
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
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
        if segmentedControl.selectedSegmentIndex == 1 {
            loadFriendRequests()
        } else {
            users.removeAll()
            tableView.reloadData()
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
        
        let endPrefix = prefix + "\u{f8ff}"
        db.collection("users")
            .whereField("email", isGreaterThanOrEqualTo: prefix)
            .whereField("email", isLessThan: endPrefix)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else { return }
                
                self.users = documents.compactMap { document -> FriendUser? in
                    let data = document.data()
                    guard let email = data["email"] as? String,
                          let name = data["name"] as? String else { return nil }
                    let avatar = data["avatar"] as? String ?? "wizard"
                    return FriendUser(id: document.documentID, email: email, name: name, avatar: avatar)
                }
                
                // Kullanıcıların arkadaşlık durumlarını kontrol et
                self.checkFriendshipStatus()
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
                    self?.showAlert(title: "Başarılı", message: "Arkadaşlık isteği gönderildi.")
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
        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
        present(alert, animated: true)
    }
}

extension FriendsViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchUsers(with: searchText)
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
            cell.delegate = self
            cell.configure(with: request)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if segmentedControl.selectedSegmentIndex == 0 {
            let user = users[indexPath.row]
            
            // Eğer zaten arkadaşsa veya istek beklemedeyse, işlem yapma
            guard !friendIds.contains(user.id) && !pendingRequestIds.contains(user.id) else {
                return
            }
            
            let alert = UIAlertController(title: "Arkadaşlık İsteği",
                                        message: "\(user.name) kullanıcısına arkadaşlık isteği göndermek istiyor musunuz?",
                                        preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "İptal", style: .cancel))
            alert.addAction(UIAlertAction(title: "Gönder", style: .default) { [weak self] _ in
                self?.sendFriendRequest(to: user)
            })
            
            present(alert, animated: true)
        } else {
            let request = friendRequests[indexPath.row]
            let alert = UIAlertController(title: "Arkadaşlık İsteği",
                                        message: "\(request.senderEmail) kullanıcısından gelen arkadaşlık isteğini yanıtlayın.",
                                        preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Reddet", style: .destructive) { [weak self] _ in
                self?.handleFriendRequest(request, accepted: false)
            })
            alert.addAction(UIAlertAction(title: "Kabul Et", style: .default) { [weak self] _ in
                self?.handleFriendRequest(request, accepted: true)
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
            emptyStateLabel.text = "Arama sonucu bulunamadı"
        } else {
            emptyStateLabel.isHidden = !friendRequests.isEmpty
            emptyStateLabel.text = "Bekleyen istek yok"
        }
    }
}

extension FriendsViewController: FriendRequestCellDelegate {
    func didTapAccept(for request: FriendRequest) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // UI'da loading göster
        showLoadingView()
        
        // Önce arkadaş listelerine ekle
        let batch = db.batch()
        
        // Current user'ın friends array'ine ekle
        let currentUserRef = db.collection("users").document(currentUserId)
        batch.updateData([
            "friends": FieldValue.arrayUnion([request.senderId])
        ], forDocument: currentUserRef)
        
        // Gönderen kişinin friends array'ine ekle
        let senderRef = db.collection("users").document(request.senderId)
        batch.updateData([
            "friends": FieldValue.arrayUnion([currentUserId])
        ], forDocument: senderRef)
        
        // İsteği kabul edildi olarak işaretle
        let requestRef = db.collection("friendRequests").document(request.id)
        batch.updateData([
            "status": "accepted"
        ], forDocument: requestRef)
        
        // Batch işlemini gerçekleştir
        batch.commit { [weak self] error in
            DispatchQueue.main.async {
                self?.hideLoadingView()
                
                if let error = error {
                    self?.showAlert(title: "Hata", message: "İstek kabul edilirken bir hata oluştu: \(error.localizedDescription)")
                    return
                }
                
                // UI'ı güncelle
                if let index = self?.friendRequests.firstIndex(where: { $0.id == request.id }) {
                    self?.friendRequests.remove(at: index)
                    self?.tableView.reloadData()
                }
                
                // Arkadaş listesini yenile
                self?.checkFriendshipStatus()
            }
        }
    }
    
    func didTapReject(for request: FriendRequest) {
        // UI'da loading göster
        showLoadingView()
        
        // İsteği reddet
        let requestRef = db.collection("friendRequests").document(request.id)
        requestRef.updateData([
            "status": "rejected"
        ]) { [weak self] error in
            DispatchQueue.main.async {
                self?.hideLoadingView()
                
                if let error = error {
                    self?.showAlert(title: "Hata", message: "İstek reddedilirken bir hata oluştu: \(error.localizedDescription)")
                    return
                }
                
                // UI'ı güncelle
                if let index = self?.friendRequests.firstIndex(where: { $0.id == request.id }) {
                    self?.friendRequests.remove(at: index)
                    self?.tableView.reloadData()
                }
            }
        }
    }
    
    private func showLoadingView() {
        // LoadingView'ı göster
        let loadingView = UIView(frame: view.bounds)
        loadingView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        loadingView.tag = 999
        
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.center = loadingView.center
        indicator.startAnimating()
        
        loadingView.addSubview(indicator)
        view.addSubview(loadingView)
    }
    
    private func hideLoadingView() {
        // LoadingView'ı kaldır
        view.subviews.first(where: { $0.tag == 999 })?.removeFromSuperview()
    }
} 
