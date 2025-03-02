import SwiftUI

struct QuizDetailView: View {
    let quiz: Quiz
    @StateObject private var viewModel: QuizDetailViewModel
    @State private var showStartQuizAlert = false
    @State private var navigateToQuiz = false
    
    init(quiz: Quiz) {
        self.quiz = quiz
        _viewModel = StateObject(wrappedValue: QuizDetailViewModel(quiz: quiz))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Quiz Header Image
                if let thumbnail = quiz.thumbnail {
                    AsyncImage(url: URL(string: thumbnail)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color(.systemGray5)
                    }
                    .frame(height: 200)
                    .clipped()
                }
                
                VStack(spacing: 20) {
                    // Quiz Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text(quiz.title)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(quiz.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        // Quiz Metadata
                        VStack(spacing: 8) {
                            MetadataRow(icon: "list.bullet", title: "Questions", value: "\(quiz.questions.count) questions")
                            MetadataRow(icon: "clock", title: "Time Limit", value: "\(quiz.timeLimit) minutes")
                            MetadataRow(icon: "tag", title: "Category", value: quiz.category.rawValue)
                            MetadataRow(icon: "speedometer", title: "Difficulty", value: quiz.difficulty.rawValue)
                        }
                        .padding(.vertical, 8)
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    // User Stats
                    if let stats = viewModel.userStats {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Your Statistics")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(spacing: 16) {
                                StatBox(title: "Best Score", value: "\(stats.bestScore)%", icon: "star.fill", color: .yellow)
                                StatBox(title: "Attempts", value: "\(stats.attempts)", icon: "repeat", color: .blue)
                                StatBox(title: "Avg Score", value: "\(stats.averageScore)%", icon: "chart.bar.fill", color: .green)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Start Quiz Button
                    Button(action: { showStartQuizAlert = true }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Start Quiz")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .alert(isPresented: $showStartQuizAlert) {
                        Alert(
                            title: Text("Start Quiz"),
                            message: Text("Are you ready to start? The timer will begin immediately."),
                            primaryButton: .default(Text("Start")) {
                                navigateToQuiz = true
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToQuiz) {
            QuizSessionView(quiz: quiz)
        }
        .onAppear {
            viewModel.loadQuizStats()
        }
    }
}

struct MetadataRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
        }
    }
}

// Placeholder for QuizSessionView
struct QuizSessionView: View {
    let quiz: Quiz
    
    var body: some View {
        Text("Quiz Session View - To be implemented")
    }
} 