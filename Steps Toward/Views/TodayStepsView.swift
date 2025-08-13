import SwiftUI

struct TodayStepsView: View {
    @State private var healthKitManager = HealthKitManager()
    private let dailyGoal = 10000 // Configurable daily step goal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Progress")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "figure.walk.motion")
                            .foregroundStyle(Color.accent)
                        
                        Text("Steps Today")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text("\(healthKitManager.todaySteps.formatted())")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.accent)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 8)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: min(1.0, Double(healthKitManager.todaySteps) / Double(dailyGoal)))
                        .stroke(Color.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.0), value: healthKitManager.todaySteps)
                    
                    Text("\(Int((Double(healthKitManager.todaySteps) / Double(dailyGoal)) * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            
            HStack {
                Text("Daily Goal: \(dailyGoal.formatted()) steps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if healthKitManager.todaySteps >= dailyGoal {
                    Text("Goal Reached! 🎉")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else {
                    Text("\((dailyGoal - healthKitManager.todaySteps).formatted()) to go")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .onAppear {
            healthKitManager.fetchTodaySteps()
        }
    }
}

#Preview {
    TodayStepsView()
        .padding()
}
