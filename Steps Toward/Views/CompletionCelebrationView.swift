import SwiftUI

struct CompletionCelebrationView: View {
    let goal: StepGoal
    @Environment(\.dismiss) private var dismiss
    @State private var showingConfetti = false
    @State private var scale: CGFloat = 0.8
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.green.opacity(0.3), Color.blue.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(Color.yellow)
                            .frame(width: 120, height: 120)
                            .shadow(radius: 10)
                        
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.white)
                    }
                    .scaleEffect(scale)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6), value: scale)
                    
                    VStack(spacing: 12) {
                        Text("🎉 Congratulations! 🎉")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("You've completed the")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        
                        Text(goal.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                        
                        Text("You walked \(goal.totalSteps.formatted()) steps!")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    
                    VStack(spacing: 16) {
                        achievementRow(
                            icon: "calendar",
                            title: "Journey Duration",
                            value: "\(daysBetween(goal.startDate, Date())) days"
                        )
                        
                        achievementRow(
                            icon: "figure.walk",
                            title: "Daily Average",
                            value: "\(Int(goal.totalSteps / max(1, daysBetween(goal.startDate, Date())))).formatted()) steps"
                        )
                        
                        achievementRow(
                            icon: "map",
                            title: "Distance Traveled",
                            value: "~\(Int(Double(goal.totalSteps) * 0.0005)) miles"
                        )
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(radius: 5)
                    )
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    Button {
                        shareAchievement()
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Achievement")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding()
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Continue")
                            .font(.headline)
                            .foregroundStyle(.blue)
                            .padding()
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding()
            
            if showingConfetti {
                ConfettiView()
            }
        }
        .onAppear {
            scale = 1.0
            showingConfetti = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                showingConfetti = false
            }
        }
    }
    
    private func achievementRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
    
    private func daysBetween(_ start: Date, _ end: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: start, to: end)
        return max(1, components.day ?? 1)
    }
    
    private func shareAchievement() {
        let text = "🎉 I just completed the \(goal.name)! I walked \(goal.totalSteps.formatted()) steps over \(daysBetween(goal.startDate, Date())) days using Steps Toward! #StepsToward #FitnessJourney"
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        window.rootViewController?.present(activityVC, animated: true)
    }
}

struct ConfettiView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            ForEach(0..<50, id: \.self) { _ in
                ConfettiPiece()
            }
        }
        .onAppear {
            animate = true
        }
    }
}

struct ConfettiPiece: View {
    @State private var yOffset: CGFloat = -100
    @State private var xOffset: CGFloat = 0
    @State private var rotation: Double = 0
    
    private let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink]
    private let randomColor: Color
    private let randomX: CGFloat
    private let randomDelay: Double
    
    init() {
        randomColor = colors.randomElement() ?? .blue
        randomX = CGFloat.random(in: -200...200)
        randomDelay = Double.random(in: 0...2)
    }
    
    var body: some View {
        Rectangle()
            .fill(randomColor)
            .frame(width: 8, height: 8)
            .offset(x: xOffset, y: yOffset)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.easeOut(duration: 3).delay(randomDelay)) {
                    yOffset = UIScreen.main.bounds.height + 100
                    xOffset = randomX
                    rotation = Double.random(in: 360...720)
                }
            }
    }
}

#Preview {
    CompletionCelebrationView(goal: TrailGoals.oregonTrail)
}
