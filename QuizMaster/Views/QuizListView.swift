import SwiftUI

struct QuizListView: View {
    @StateObject private var viewModel = QuizListViewModel()
    @State private var showFilters = false
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Search and Filter Bar
                HStack {
                    SearchBar(text: $viewModel.searchText)
                    
                    Button(action: { showFilters.toggle() }) {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(.blue)
                            .font(.system(size: 20, weight: .medium))
                    }
                    .sheet(isPresented: $showFilters) {
                        FilterView(
                            selectedCategory: $viewModel.selectedCategory,
                            selectedDifficulty: $viewModel.selectedDifficulty
                        )
                    }
                }
                .padding(.horizontal)
                
                // Categories ScrollView
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(QuizCategory.allCases, id: \.self) { category in
                            CategoryButton(
                                category: category,
                                isSelected: viewModel.selectedCategory == category,
                                action: {
                                    withAnimation {
                                        viewModel.selectedCategory = viewModel.selectedCategory == category ? nil : category
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Quiz List
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.filteredQuizzes()) { quiz in
                                QuizCard(quiz: quiz)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
        }
        .navigationTitle("Quizzes")
        .onAppear {
            viewModel.loadQuizzes()
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search quizzes...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct CategoryButton: View {
    let category: QuizCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.rawValue)
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct QuizCard: View {
    let quiz: Quiz
    
    var body: some View {
        NavigationLink(destination: QuizDetailView(quiz: quiz)) {
            VStack(alignment: .leading, spacing: 12) {
                // Thumbnail
                if let thumbnail = quiz.thumbnail {
                    AsyncImage(url: URL(string: thumbnail)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color(.systemGray5)
                    }
                    .frame(height: 150)
                    .cornerRadius(12)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(quiz.title)
                        .font(.headline)
                    
                    Text(quiz.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    HStack {
                        Label("\(quiz.questions.count) Questions", systemImage: "list.bullet")
                        Spacer()
                        Label("\(quiz.timeLimit) min", systemImage: "clock")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
}

struct FilterView: View {
    @Binding var selectedCategory: QuizCategory?
    @Binding var selectedDifficulty: QuizDifficulty?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Category")) {
                    ForEach(QuizCategory.allCases, id: \.self) { category in
                        HStack {
                            Text(category.rawValue)
                            Spacer()
                            if selectedCategory == category {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedCategory = selectedCategory == category ? nil : category
                        }
                    }
                }
                
                Section(header: Text("Difficulty")) {
                    ForEach(QuizDifficulty.allCases, id: \.self) { difficulty in
                        HStack {
                            Text(difficulty.rawValue)
                            Spacer()
                            if selectedDifficulty == difficulty {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedDifficulty = selectedDifficulty == difficulty ? nil : difficulty
                        }
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// Placeholder for QuizDetailView
struct QuizDetailView: View {
    let quiz: Quiz
    
    var body: some View {
        Text("Quiz Detail View - To be implemented")
    }
} 