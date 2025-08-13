// Full file content for StepGoal.swift
import Foundation

/// Represents a step goal with progress tracking.
struct StepGoal: Identifiable, Codable {
    let id = UUID()
    let name: String
    let totalSteps: Int
    let description: String
    var startDate: Date
    var currentSteps: Int = 0
    var dailyProgress: [DailyProgress] = []
    
    /// The progress as a percentage (0.0 to 1.0).
    var progressPercentage: Double {
        Double(currentSteps) / Double(totalSteps)
    }
    
    /// Whether the goal has been completed.
    var isCompleted: Bool {
        currentSteps >= totalSteps
    }
    
    /// Remaining steps to complete the goal.
    var remainingSteps: Int {
        max(0, totalSteps - currentSteps)
    }
}
