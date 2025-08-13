import SwiftUI

struct ProgressTrailView: View {
    let goal: StepGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Journey")
                .font(.headline)
            
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.tertiarySystemBackground))
                    .frame(height: 60)
                
                HStack {
                    VStack {
                        Image(systemName: "house.fill")
                            .foregroundStyle(.green)
                        Text("Start")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack {
                        Image(systemName: destinationIcon(for: goal.name))
                            .foregroundStyle(goal.isCompleted ? .green : .gray)
                        Text("Goal")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                
                GeometryReader { geometry in
                    HStack {
                        Spacer()
                            .frame(width: geometry.size.width * goal.progressPercentage)
                        
                        VStack {
                            Image(systemName: "figure.walk")
                                .foregroundStyle(Color.accent)
                                .font(.title2)
                                .scaleEffect(1.2)
                            
                            Text("You")
                                .font(.caption2)
                                .foregroundStyle(Color.accent)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                    }
                }
            }
            
            MilestonesView(goal: goal)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    private func destinationIcon(for trailName: String) -> String {
        switch trailName {
        case "Oregon Trail": return "mountain.2.fill"
        case "Santa Fe Trail": return "building.2.fill"
        case "California Trail": return "sun.max.fill"
        case "Appalachian Trail": return "tree.fill"
        case "Camino de Santiago": return "cross.fill"
        case "Pacific Crest Trail": return "mountain.2.fill"
        default: return "flag.fill"
        }
    }
}

struct MilestonesView: View {
    let goal: StepGoal
    
    private var milestones: [Int] {
        let interval = goal.totalSteps / 4
        return (1...3).map { $0 * interval }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Trail Milestones")
                .font(.subheadline)
                .fontWeight(.medium)
            
            ForEach(milestones, id: \.self) { milestone in
                HStack {
                    Image(systemName: goal.currentSteps >= milestone ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(goal.currentSteps >= milestone ? .green : .gray)
                    
                    Text("\(milestone.formatted()) steps")
                        .font(.caption)
                        .foregroundStyle(goal.currentSteps >= milestone ? .primary : .secondary)
                    
                    Spacer()
                    
                    if goal.currentSteps >= milestone {
                        Text("✓ Completed")
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else {
                        Text("\((milestone - goal.currentSteps).formatted()) to go")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.top, 8)
    }
}

#Preview {
    ProgressTrailView(goal: TrailGoals.oregonTrail)
        .padding()
}
