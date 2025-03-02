import SwiftUI

struct HomeView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Welcome Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome back!")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Ready to challenge yourself?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                // Stats Cards
                HStack(spacing: 16) {
                    StatCard(title: "Total Points", value: "1,234", icon: "star.fill", color: .yellow)
                    StatCard(title: "Quizzes Done", value: "25", icon: "checkmark.circle.fill", color: .green)
                }
                .padding(.horizontal)
                
                // Featured Quizzes
                VStack(alignment: .leading, spacing: 16) {
                    Text("Featured Quizzes")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(0..<5) { _ in
                                FeaturedQuizCard()
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Recent Activity
                VStack(alignment: .leading, spacing: 16) {
                    Text("Recent Activity")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        ForEach(0..<3) { _ in
                            ActivityCard()
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Home")
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 24))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct FeaturedQuizCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Placeholder Image
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(width: 280, height: 160)
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Science Quiz")
                    .font(.headline)
                
                Text("Test your knowledge about the solar system")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Label("15 Questions", systemImage: "list.bullet")
                    Spacer()
                    Label("20 min", systemImage: "clock")
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
        .frame(width: 280)
    }
}

struct ActivityCard: View {
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 48, height: 48)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Completed History Quiz")
                    .font(.headline)
                
                Text("Score: 85/100")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("2h ago")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
} 