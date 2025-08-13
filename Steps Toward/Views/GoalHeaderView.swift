import SwiftUI

struct GoalHeaderView: View {
    let goal: StepGoal
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: trailIcon(for: goal.name))
                    .font(.title2)
                    .foregroundStyle(Color.accent)
                
                VStack(alignment: .leading) {
                    Text(goal.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(goal.totalSteps.formatted()) steps")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Progress")
                        .font(.headline)
                    Spacer()
                    Text("\(Int(goal.progressPercentage * 100))%")
                        .font(.headline)
                        .foregroundStyle(goal.isCompleted ? .green : Color.accent)
                }
                
                ProgressView(value: goal.progressPercentage)
                    .tint(goal.isCompleted ? .green : Color.accent)
                
                HStack {
                    Text("\(goal.currentSteps.formatted()) / \(goal.totalSteps.formatted())")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    if !goal.isCompleted {
                        Text("\(goal.remainingSteps.formatted()) to go")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Trail Completed! 🎉")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(goal.name) progress: \(Int(goal.progressPercentage * 100)) percent complete")
    }
    
    private func trailIcon(for trailName: String) -> String {
        switch trailName {
        case "Oregon Trail": return "mountain.2"
        case "Santa Fe Trail": return "sun.max"
        case "California Trail": return "beach.umbrella"
        case "Appalachian Trail": return "tree"
        case "Camino de Santiago": return "cross"
        case "Pacific Crest Trail": return "mountain.2.fill"
        default: return "map"
        }
    }
}

#Preview {
    GoalHeaderView(goal: TrailGoals.oregonTrail)
        .padding()
}
