import SwiftUI

struct GoalSelectionView: View {
    let stepGoalManager: StepGoalManager
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var filteredTrails: [StepGoal] {
        let trails = TrailGoals.allTrails
        if searchText.isEmpty {
            return trails.sorted { $0.totalSteps < $1.totalSteps }
        } else {
            return trails.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        Image(systemName: "map.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(Color.accent)
                        
                        Text("Choose Your Trail")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Select a historic trail to follow. Each step you take will bring you closer to your destination!")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    
                    LazyVStack(spacing: 16) {
                        ForEach(filteredTrails, id: \.name) { trail in
                            TrailOptionView(trail: trail) {
                                stepGoalManager.setGoal(trail)
                                dismiss()
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Select Trail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search trails")
        }
    }
}

struct TrailOptionView: View {
    let trail: StepGoal
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: trailIcon(for: trail.name))
                        .font(.title2)
                        .foregroundStyle(Color.accent)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(trail.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Text("\(trail.totalSteps.formatted()) steps")
                            .font(.subheadline)
                            .foregroundStyle(Color.accent)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text(trail.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                
                let estimatedDays = trail.totalSteps / 8000
                Text("Estimated: \(estimatedDays) days at 8,000 steps/day")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
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
    GoalSelectionView(stepGoalManager: StepGoalManager())
}
