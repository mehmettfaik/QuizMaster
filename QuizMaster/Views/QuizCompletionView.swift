import SwiftUI

struct QuizCompletionView: View {
    let quiz: Quiz
    let answers: [QuestionAnswer]
    let onDismiss: () -> Void
    @State private var showReview = false
    
    private var score: Int {
        let correctAnswers = answers.filter { $0.isCorrect }.count
        return Int((Float(correctAnswers) / Float(quiz.questions.count)) * 100)
    }
    
    var body: some View {
        VStack(spacing: 32) {
            // Score Circle
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 20)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .trim(from: 0, to: CGFloat(score) / 100)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: score)
                
                VStack {
                    Text("\(score)%")
                        .font(.system(size: 48, weight: .bold))
                        .transition(.scale.combined(with: .opacity))
                    Text("Score")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            
            // Stats
            VStack(spacing: 16) {
                StatRow(title: "Correct Answers", value: "\(answers.filter { $0.isCorrect }.count)/\(quiz.questions.count)")
                StatRow(title: "Time Taken", value: timeString(from: Int(answers.reduce(0) { $0 + $1.timeSpent })))
                StatRow(title: "Average Time per Question", value: "\(Int(answers.reduce(0) { $0 + $1.timeSpent } / Double(answers.count)))s")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Action Buttons
            VStack(spacing: 12) {
                NavigationLink(destination: QuizReviewView(quiz: quiz, answers: answers)) {
                    HStack {
                        Image(systemName: "list.bullet")
                        Text("Review Answers")
                    }
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                
                Button(action: onDismiss) {
                    Text("Done")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
        }
        .padding()
    }
    
    private var scoreColor: Color {
        switch score {
        case 0..<60: return .red
        case 60..<80: return .orange
        default: return .green
        }
    }
    
    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return "\(minutes)m \(remainingSeconds)s"
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
} 