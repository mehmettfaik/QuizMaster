import SwiftUI

struct QuizSessionView: View {
    @StateObject private var viewModel: QuizSessionViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showQuitAlert = false
    
    init(quiz: Quiz) {
        _viewModel = StateObject(wrappedValue: QuizSessionViewModel(quiz: quiz))
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            if viewModel.isCompleted {
                QuizCompletionView(
                    quiz: viewModel.quiz,
                    answers: viewModel.answers,
                    onDismiss: { dismiss() }
                )
            } else {
                VStack(spacing: 20) {
                    // Progress and Timer
                    HStack {
                        // Progress Bar
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Question \(viewModel.currentQuestionIndex + 1) of \(viewModel.quiz.questions.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ProgressView(value: viewModel.progress)
                                .tint(.blue)
                        }
                        
                        Spacer()
                        
                        // Timer
                        HStack {
                            Image(systemName: "clock")
                            Text(timeString(from: viewModel.timeRemaining))
                        }
                        .font(.headline)
                        .foregroundColor(viewModel.timeRemaining < 60 ? .red : .primary)
                    }
                    .padding()
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            // Question
                            Text(viewModel.currentQuestion.text)
                                .font(.title3)
                                .fontWeight(.medium)
                                .padding(.horizontal)
                            
                            // Options
                            VStack(spacing: 12) {
                                ForEach(Array(viewModel.currentQuestion.options.enumerated()), id: \.offset) { index, option in
                                    AnswerOptionButton(
                                        text: option,
                                        isSelected: viewModel.selectedAnswer == index,
                                        action: { viewModel.selectAnswer(index) }
                                    )
                                }
                            }
                            .padding(.horizontal)
                            
                            // Explanation (if shown)
                            if viewModel.showExplanation, let explanation = viewModel.currentQuestion.explanation {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Explanation")
                                        .font(.headline)
                                    
                                    Text(explanation)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Bottom Buttons
                    VStack(spacing: 12) {
                        Button(action: { viewModel.nextQuestion() }) {
                            Text(viewModel.isLastQuestion ? "Finish Quiz" : "Next Question")
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(viewModel.selectedAnswer == nil ? Color.gray : Color.blue)
                                .cornerRadius(12)
                        }
                        .disabled(viewModel.selectedAnswer == nil)
                        
                        if viewModel.currentQuestion.explanation != nil {
                            Button(action: { viewModel.toggleExplanation() }) {
                                Text(viewModel.showExplanation ? "Hide Explanation" : "Show Explanation")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: { showQuitAlert = true }) {
            Image(systemName: "xmark")
                .foregroundColor(.primary)
        })
        .alert("Quit Quiz?", isPresented: $showQuitAlert) {
            Button("Quit", role: .destructive) { dismiss() }
            Button("Continue", role: .cancel) { }
        } message: {
            Text("Your progress will be lost.")
        }
        .onAppear {
            viewModel.startQuiz()
        }
    }
    
    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

struct AnswerOptionButton: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: 2)
            )
        }
        .foregroundColor(.primary)
    }
}

struct QuizCompletionView: View {
    let quiz: Quiz
    let answers: [QuestionAnswer]
    let onDismiss: () -> Void
    
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
                
                VStack {
                    Text("\(score)%")
                        .font(.system(size: 48, weight: .bold))
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
                Button(action: {
                    // TODO: Show detailed review
                }) {
                    Text("Review Answers")
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