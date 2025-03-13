import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

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
} 