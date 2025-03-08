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
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var error: Error?
    
    private var cancellables = Set<AnyCancellable>()
    private let db = Firestore.firestore()
    
    // MARK: - User Data Loading
    func loadUserProfile() {
        guard let userId = Auth.auth().currentUser?.uid else {
            self.error = NSError(domain: "UserError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı girişi yapılmamış"])
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
    func updateUserScore(points: Int, won: Bool) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let userRef = db.collection("users").document(userId)
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let document: DocumentSnapshot
            do {
                try document = transaction.getDocument(userRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard let oldPoints = document.data()?["total_points"] as? Int,
                  let oldQuizzesPlayed = document.data()?["quizzes_played"] as? Int,
                  let oldQuizzesWon = document.data()?["quizzes_won"] as? Int else {
                return nil
            }
            
            transaction.updateData([
                "total_points": oldPoints + points,
                "quizzes_played": oldQuizzesPlayed + 1,
                "quizzes_won": oldQuizzesWon + (won ? 1 : 0)
            ], forDocument: userRef)
            
            return nil
        }) { [weak self] (_, error) in
            if let error = error {
                print("❌ Error updating score: \(error.localizedDescription)")
            } else {
                print("✅ Score updated successfully")
                self?.loadUserProfile()
            }
        }
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
} 