import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

// MARK: - Achievement Badge
struct AchievementBadge {
    let id: String
    let title: String
    let description: String
    let icon: String
    let isUnlocked: Bool
    let progress: Double // 0.0 to 1.0
    let requirement: Int
    let currentValue: Int
}

class UserViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var userName: String = ""
    @Published private(set) var userEmail: String = ""
    @Published private(set) var userAvatar: String = "wizard" // Default avatar
    @Published private(set) var totalPoints: Int = 0
    @Published private(set) var quizzesPlayed: Int = 0
    @Published private(set) var quizzesWon: Int = 0
    @Published private(set) var worldRank: Int = 0
    @Published private(set) var categoryStats: [String: CategoryStats] = [:]
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var error: Error?
    @Published private(set) var achievements: [AchievementBadge] = []
    @Published private(set) var isDarkMode: Bool = false
    @Published private(set) var language: String = "tr"
    @Published private(set) var notificationsEnabled: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private let db = Firestore.firestore()
    
    var currentUserId: String? {
        return Auth.auth().currentUser?.uid
    }
    
    // MARK: - User Data Loading
    func loadUserProfile() {
        guard let userId = Auth.auth().currentUser?.uid else {
            self.error = NSError(domain: "UserError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
            return
        }
        
        isLoading = true
        
        db.collection("users").document(userId).getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("❌ Error loading user profile: \(error.localizedDescription)")
                    self.error = error
                    return
                }
                
                guard let document = document, document.exists,
                      let data = document.data() else {
                    print("❌ User document not found")
                    return
                }
                
                self.userName = data["name"] as? String ?? ""
                self.userEmail = data["email"] as? String ?? ""
                self.userAvatar = data["avatar"] as? String ?? "wizard"
                self.totalPoints = data["total_points"] as? Int ?? 0
                self.quizzesPlayed = data["quizzes_played"] as? Int ?? 0
                self.quizzesWon = data["quizzes_won"] as? Int ?? 0
                
                // Parse category stats
                if let stats = data["category_stats"] as? [String: [String: Any]] {
                    var parsedStats: [String: CategoryStats] = [:]
                    for (category, statData) in stats {
                        parsedStats[category] = CategoryStats(
                            correctAnswers: statData["correct_answers"] as? Int ?? 0,
                            wrongAnswers: statData["wrong_answers"] as? Int ?? 0,
                            point: statData["point"] as? Int ?? 0
                        )
                    }
                    self.categoryStats = parsedStats
                }
                
                // Calculate achievements after loading data
                self.calculateAchievements()
                
                // World Rank hesaplama
                self.calculateWorldRank(userId: userId, currentUserPoints: self.totalPoints)
            }
        }
    }
    
    // MARK: - World Rank Calculation
    private func calculateWorldRank(userId: String, currentUserPoints: Int) {
        db.collection("users")
            .order(by: "total_points", descending: true)
            .getDocuments { [weak self] (snapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error calculating world rank: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("❌ No users found")
                    return
                }
                
                // Kullanıcının sırasını bul
                if let userRank = documents.firstIndex(where: { $0.documentID == userId }) {
                    DispatchQueue.main.async {
                        self.worldRank = userRank + 1
                        print("✅ World Rank: \(self.worldRank)")
                    }
                }
                
                // Debug bilgileri
                print("📊 Rankings:")
                documents.enumerated().forEach { index, doc in
                    let data = doc.data()
                    let name = data["name"] as? String ?? "Unknown"
                    let points = data["total_points"] as? Int ?? 0
                    print("   \(index + 1). \(name): \(points) points")
                }
            }
    }
    
    // MARK: - Score Update
    func updateUserScore(category: String, correctAnswers: Int, wrongAnswers: Int, points: Int) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        FirebaseService.shared.updateUserScore(
            userId: userId,
            category: category,
            correctAnswers: correctAnswers,
            wrongAnswers: wrongAnswers,
            points: points
        )
        
        // Reload user profile to get updated stats
        loadUserProfile()
    }
    
    // MARK: - Sign Out
    func signOut() {
        do {
            try Auth.auth().signOut()
            print("✅ Successfully signed out")
        } catch {
            print("❌ Error signing out: \(error.localizedDescription)")
        }
    }
    
    // MARK: - User Data Update
    func updateUserName(_ newName: String, completion: @escaping (Error?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(NSError(domain: "UserError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
            return
        }
        
        let userRef = db.collection("users").document(userId)
        
        userRef.updateData([
            "name": newName
        ]) { error in
            if let error = error {
                print("❌ Error updating user name: \(error.localizedDescription)")
                completion(error)
            } else {
                print("✅ User name updated successfully")
                self.userName = newName
                completion(nil)
            }
        }
    }
    
    private func calculateAchievements() {
        let badges: [AchievementBadge] = [
            // Points Badges
            AchievementBadge(
                id: "points_100",
                title: LanguageManager.shared.localizedString(for: "rookie"),
                description: LanguageManager.shared.localizedString(for: "collect_100_points"),
                icon: "medal.fill",
                isUnlocked: totalPoints >= 100,
                progress: min(Double(totalPoints) / 100.0, 1.0),
                requirement: 100,
                currentValue: totalPoints
            ),
            AchievementBadge(
                id: "points_500",
                title: LanguageManager.shared.localizedString(for: "expert"),
                description: LanguageManager.shared.localizedString(for: "collect_500_points"),
                icon: "bolt.circle.fill",
                isUnlocked: totalPoints >= 500,
                progress: min(Double(totalPoints) / 500.0, 1.0),
                requirement: 500,
                currentValue: totalPoints
            ),
            AchievementBadge(
                id: "points_1000",
                title: LanguageManager.shared.localizedString(for: "legend"),
                description: LanguageManager.shared.localizedString(for: "collect_1000_points"),
                icon: "star.square.fill",
                isUnlocked: totalPoints >= 1000,
                progress: min(Double(totalPoints) / 1000.0, 1.0),
                requirement: 1000,
                currentValue: totalPoints
            ),
            
            // Quiz Count Badges
            AchievementBadge(
                id: "quiz_5",
                title: LanguageManager.shared.localizedString(for: "quiz_lover"),
                description: LanguageManager.shared.localizedString(for: "complete_5_quizzes"),
                icon: "checkmark.circle.fill",
                isUnlocked: quizzesPlayed >= 5,
                progress: min(Double(quizzesPlayed) / 5.0, 1.0),
                requirement: 5,
                currentValue: quizzesPlayed
            ),
            AchievementBadge(
                id: "quiz_20",
                title: LanguageManager.shared.localizedString(for: "quiz_pro"),
                description: LanguageManager.shared.localizedString(for: "complete_20_quizzes"),
                icon: "trophy.fill",
                isUnlocked: quizzesPlayed >= 20,
                progress: min(Double(quizzesPlayed) / 20.0, 1.0),
                requirement: 20,
                currentValue: quizzesPlayed
            ),
            
            // Rank Badge
            AchievementBadge(
                id: "rank_top_10",
                title: LanguageManager.shared.localizedString(for: "elite"),
                description: LanguageManager.shared.localizedString(for: "reach_top_10"),
                icon: "crown.fill",
                isUnlocked: worldRank <= 10,
                progress: worldRank <= 10 ? 1.0 : 0.0,
                requirement: 10,
                currentValue: worldRank
            )
        ]
        
        DispatchQueue.main.async {
            self.achievements = badges
        }
    }
    
    // MARK: - Settings Operations
    func updateAvatar(_ avatar: String, completion: @escaping (Error?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(NSError(domain: "UserError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
            return
        }
        
        let userRef = db.collection("users").document(userId)
        userRef.updateData([
            "avatar": avatar
        ]) { [weak self] error in
            if error == nil {
                self?.userAvatar = avatar
            }
            completion(error)
        }
    }
    
    func updateProfilePhoto(imageData: Data, completion: @escaping (Error?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(NSError(domain: "UserError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
            return
        }
        
        FirebaseService.shared.uploadProfileImage(userId: userId, imageData: imageData) { [weak self] result in
            switch result {
            case .success(let url):
                // Update user's photo URL in Firestore
                let userRef = self?.db.collection("users").document(userId)
                userRef?.updateData(["photoURL": url]) { error in
                    completion(error)
                }
            case .failure(let error):
                completion(error)
            }
        }
    }
    
    func updatePassword(currentPassword: String, newPassword: String, completion: @escaping (Error?) -> Void) {
        guard let user = Auth.auth().currentUser,
              let email = user.email else {
            completion(NSError(domain: "UserError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
            return
        }
        
        // Reauthenticate before changing password
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        user.reauthenticate(with: credential) { _, error in
            if let error = error {
                completion(error)
                return
            }
            
            // Change password
            user.updatePassword(to: newPassword) { error in
                completion(error)
            }
        }
    }
    
    func deleteAccount(password: String, completion: @escaping (Error?) -> Void) {
        guard let user = Auth.auth().currentUser,
              let email = user.email else {
            completion(NSError(domain: "UserError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
            return
        }
        
        // Reauthenticate before deleting account
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        user.reauthenticate(with: credential) { [weak self] _, error in
            if let error = error {
                completion(error)
                return
            }
            
            // Delete user data from Firestore
            self?.db.collection("users").document(user.uid).delete { error in
                if let error = error {
                    completion(error)
                    return
                }
                
                // Delete user account
                user.delete { error in
                    completion(error)
                }
            }
        }
    }
    
    func updateLanguage(_ language: String, completion: @escaping (Error?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(NSError(domain: "UserError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
            return
        }
        
        let userRef = db.collection("users").document(userId)
        userRef.updateData(["language": language]) { [weak self] error in
            if error == nil {
                self?.language = language
                // Dil değişikliğini LanguageManager'a bildir
                LanguageManager.shared.currentLanguage = language
            }
            completion(error)
        }
    }
    
    func updateTheme(isDark: Bool) {
        isDarkMode = isDark
        if #available(iOS 13.0, *) {
            let scenes = UIApplication.shared.connectedScenes
            let windowScene = scenes.first as? UIWindowScene
            let window = windowScene?.windows.first
            window?.overrideUserInterfaceStyle = isDark ? .dark : .light
        }
    }
    
    func updateNotificationSettings(enabled: Bool) {
        notificationsEnabled = enabled
        // Implement notification settings update logic
    }
} 
