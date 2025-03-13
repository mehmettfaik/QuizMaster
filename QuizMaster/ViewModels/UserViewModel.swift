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
    @Published private(set) var totalPoints: Int = 0
    @Published private(set) var quizzesPlayed: Int = 0
    @Published private(set) var quizzesWon: Int = 0
    @Published private(set) var worldRank: Int = 0
    @Published private(set) var categoryStats: [String: CategoryStats] = [:]
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var error: Error?
    @Published private(set) var achievements: [AchievementBadge] = []
    
    private var cancellables = Set<AnyCancellable>()
    private let db = Firestore.firestore()
    
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
                            totalPoints: statData["total_points"] as? Int ?? 0
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
                title: "Çaylak",
                description: "100 puan topla",
                icon: "star.circle.fill",
                isUnlocked: totalPoints >= 100,
                progress: min(Double(totalPoints) / 100.0, 1.0),
                requirement: 100,
                currentValue: totalPoints
            ),
            AchievementBadge(
                id: "points_500",
                title: "Uzman",
                description: "500 puan topla",
                icon: "star.circle.fill",
                isUnlocked: totalPoints >= 500,
                progress: min(Double(totalPoints) / 500.0, 1.0),
                requirement: 500,
                currentValue: totalPoints
            ),
            AchievementBadge(
                id: "points_1000",
                title: "Efsane",
                description: "1000 puan topla",
                icon: "star.square.fill",
                isUnlocked: totalPoints >= 1000,
                progress: min(Double(totalPoints) / 1000.0, 1.0),
                requirement: 1000,
                currentValue: totalPoints
            ),
            
            // Quiz Count Badges
            AchievementBadge(
                id: "quiz_5",
                title: "Quiz Sever",
                description: "5 quiz tamamla",
                icon: "questionmark.circle.fill",
                isUnlocked: quizzesPlayed >= 5,
                progress: min(Double(quizzesPlayed) / 5.0, 1.0),
                requirement: 5,
                currentValue: quizzesPlayed
            ),
            AchievementBadge(
                id: "quiz_20",
                title: "Quiz Ustası",
                description: "20 quiz tamamla",
                icon: "questionmark.square.fill",
                isUnlocked: quizzesPlayed >= 20,
                progress: min(Double(quizzesPlayed) / 20.0, 1.0),
                requirement: 20,
                currentValue: quizzesPlayed
            ),
            
            // Rank Badges
            AchievementBadge(
                id: "rank_top_10",
                title: "Elit",
                description: "İlk 10'a gir",
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
} 