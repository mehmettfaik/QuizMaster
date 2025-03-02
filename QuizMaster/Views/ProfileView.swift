import SwiftUI

struct ProfileView: View {
    @State private var selectedSegment = 0
    let segments = ["Stats", "Achievements", "My Quizzes"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile Header
                VStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .foregroundColor(.blue)
                    
                    VStack(spacing: 8) {
                        Text("John Doe")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Quiz Master")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: {
                        // Edit Profile Action
                    }) {
                        Text("Edit Profile")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(20)
                    }
                }
                .padding(.top)
                
                // Segment Control
                Picker("", selection: $selectedSegment) {
                    ForEach(0..<segments.count) { index in
                        Text(segments[index]).tag(index)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Content based on selected segment
                switch selectedSegment {
                case 0:
                    StatsView()
                case 1:
                    AchievementsView()
                case 2:
                    MyQuizzesView()
                default:
                    EmptyView()
                }
            }
        }
        .navigationTitle("Profile")
    }
}

struct StatsView: View {
    var body: some View {
        VStack(spacing: 20) {
            // Overall Stats
            VStack(spacing: 16) {
                Text("Overall Stats")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 16) {
                    StatBox(title: "Total Points", value: "1,234", icon: "star.fill", color: .yellow)
                    StatBox(title: "Quizzes Done", value: "25", icon: "checkmark.circle.fill", color: .green)
                    StatBox(title: "Avg. Score", value: "85%", icon: "chart.bar.fill", color: .blue)
                }
            }
            .padding(.horizontal)
            
            // Recent Performance
            VStack(spacing: 16) {
                Text("Recent Performance")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 12) {
                    ForEach(0..<3) { _ in
                        PerformanceCard()
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct AchievementsView: View {
    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<5) { _ in
                AchievementCard()
            }
        }
        .padding(.horizontal)
    }
}

struct MyQuizzesView: View {
    var body: some View {
        VStack(spacing: 16) {
            Button(action: {
                // Create New Quiz Action
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create New Quiz")
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(12)
            }
            
            ForEach(0..<3) { _ in
                MyQuizCard()
            }
        }
        .padding(.horizontal)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 24))
            
            Text(value)
                .font(.headline)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PerformanceCard: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("History Quiz")
                    .font(.headline)
                
                Text("Completed • 2h ago")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("85%")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.green)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct AchievementCard: View {
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 30))
                .foregroundColor(.yellow)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Quiz Master")
                    .font(.headline)
                
                Text("Complete 10 quizzes with perfect scores")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("5/10")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct MyQuizCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Science Quiz")
                        .font(.headline)
                    
                    Text("15 Questions • 20 min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Menu {
                    Button(action: {}) {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(action: {}) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                }
            }
            
            HStack {
                Label("25 Attempts", systemImage: "person.2.fill")
                Spacer()
                Label("4.5", systemImage: "star.fill")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
} 