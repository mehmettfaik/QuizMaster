import SwiftUI

struct QuizReviewView: View {
    @StateObject private var viewModel: QuizReviewViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(quiz: Quiz, answers: [QuestionAnswer]) {
        _viewModel = StateObject(wrappedValue: QuizReviewViewModel(quiz: quiz, answers: answers))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Progress and Navigation
            HStack {
                Button(action: viewModel.moveToPreviousQuestion) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(viewModel.currentQuestionIndex > 0 ? .blue : .gray)
                }
                .disabled(viewModel.currentQuestionIndex == 0)
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("Question \(viewModel.currentQuestionIndex + 1) of \(viewModel.quiz.questions.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ProgressView(value: viewModel.progress)
                        .tint(.blue)
                }
                .frame(maxWidth: 200)
                
                Spacer()
                
                Button(action: viewModel.moveToNextQuestion) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(viewModel.isLastQuestion ? .gray : .blue)
                }
                .disabled(viewModel.isLastQuestion)
            }
            .padding(.horizontal)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Question
                    Text(viewModel.currentQuestion.text)
                        .font(.title3)
                        .fontWeight(.medium)
                        .padding(.horizontal)
                        .transition(.opacity)
                        .id("question_\(viewModel.currentQuestionIndex)")
                    
                    // Options
                    VStack(spacing: 12) {
                        ForEach(Array(viewModel.currentQuestion.options.enumerated()), id: \.offset) { index, option in
                            ReviewAnswerButton(
                                text: option,
                                isSelected: viewModel.currentAnswer.selectedAnswer == index,
                                isCorrect: index == viewModel.currentQuestion.correctAnswer,
                                showResult: true
                            )
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal)
                    .id("options_\(viewModel.currentQuestionIndex)")
                    
                    // Question Stats
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Question Statistics")
                            .font(.headline)
                        
                        HStack(spacing: 16) {
                            StatBox(
                                title: "Time Spent",
                                value: viewModel.questionTimeString(for: viewModel.currentQuestionIndex),
                                icon: "clock",
                                color: .blue
                            )
                            
                            StatBox(
                                title: "Points",
                                value: viewModel.currentAnswer.isCorrect ? "\(viewModel.currentQuestion.points)" : "0",
                                icon: viewModel.currentAnswer.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill",
                                color: viewModel.currentAnswer.isCorrect ? .green : .red
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    
                    // Explanation
                    if let explanation = viewModel.currentQuestion.explanation {
                        VStack(alignment: .leading, spacing: 8) {
                            Button(action: viewModel.toggleExplanation) {
                                HStack {
                                    Text(viewModel.showExplanation ? "Hide Explanation" : "Show Explanation")
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.up")
                                        .rotationEffect(.degrees(viewModel.showExplanation ? 0 : 180))
                                }
                            }
                            
                            if viewModel.showExplanation {
                                Text(explanation)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 8)
                                    .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .animation(.spring(), value: viewModel.showExplanation)
                    }
                }
            }
            
            // Done Button
            Button(action: { dismiss() }) {
                Text("Done")
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ReviewAnswerButton: View {
    let text: String
    let isSelected: Bool
    let isCorrect: Bool
    let showResult: Bool
    
    private var backgroundColor: Color {
        guard showResult else { return .clear }
        if isCorrect {
            return Color.green.opacity(0.1)
        } else if isSelected && !isCorrect {
            return Color.red.opacity(0.1)
        }
        return .clear
    }
    
    private var borderColor: Color {
        guard showResult else { return Color(.systemGray4) }
        if isCorrect {
            return .green
        } else if isSelected && !isCorrect {
            return .red
        }
        return Color(.systemGray4)
    }
    
    private var iconName: String {
        if isCorrect {
            return "checkmark.circle.fill"
        } else if isSelected && !isCorrect {
            return "xmark.circle.fill"
        }
        return "circle"
    }
    
    private var iconColor: Color {
        if isCorrect {
            return .green
        } else if isSelected && !isCorrect {
            return .red
        }
        return .gray
    }
    
    var body: some View {
        HStack {
            Text(text)
                .font(.body)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            Image(systemName: iconName)
                .foregroundColor(iconColor)
        }
        .padding()
        .background(backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 2)
        )
        .cornerRadius(12)
    }
} 