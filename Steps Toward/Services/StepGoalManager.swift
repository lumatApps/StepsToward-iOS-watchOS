// Full file content for StepGoalManager.swift
import Foundation
import Observation

@Observable class StepGoalManager {
    var currentGoal: StepGoal?
    var dailyProgress: [DailyProgress] = []
    
    private let healthKitManager = HealthKitManager()
    private let userDefaultsKey = "currentStepGoal"
    
    init() {
        loadCurrentGoal()
        startObservingHealthKit()
    }
    
    private func startObservingHealthKit() {
        Task { @MainActor in
            withObservationTracking {
                _ = healthKitManager.todaySteps
            } onChange: { [weak self] in
                guard let self else { return }
                Task { @MainActor in
                    self.updateTodayProgress(steps: self.healthKitManager.todaySteps)
                    self.startObservingHealthKit() // Continue observing
                }
            }
        }
    }
    
    func setGoal(_ goal: StepGoal) {
        var newGoal = goal
        newGoal.startDate = Date()
        currentGoal = newGoal
        saveCurrentGoal()
        
        dailyProgress = []
        updateTodayProgress(steps: healthKitManager.todaySteps)
        loadHistoricalData()
    }
    
    func updateTodayProgress(steps: Int) {
        guard var goal = currentGoal else { return }
        
        let today = Calendar.current.startOfDay(for: Date())
        
        if let todayIndex = dailyProgress.firstIndex(where: { 
            Calendar.current.isDate($0.date, inSameDayAs: today) 
        }) {
            dailyProgress[todayIndex] = DailyProgress(date: today, steps: steps)
        } else {
            dailyProgress.append(DailyProgress(date: today, steps: steps))
        }
        
        goal.currentSteps = dailyProgress.reduce(0) { $0 + $1.steps }
        goal.dailyProgress = dailyProgress
        currentGoal = goal
        
        saveCurrentGoal()
    }
    
    func loadHistoricalData() {
        guard let goal = currentGoal else { return }
        
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: goal.startDate)
        let today = calendar.startOfDay(for: Date())
        
        var currentDate = startDate
        var historicalProgress: [DailyProgress] = []
        
        let group = DispatchGroup()
        
        while currentDate <= today {
            group.enter()
            
            healthKitManager.fetchStepsForDate(currentDate) { steps in
                let progress = DailyProgress(date: currentDate, steps: steps)
                historicalProgress.append(progress)
                group.leave()
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        group.notify(queue: .main) {
            self.dailyProgress = historicalProgress.sorted { $0.date < $1.date }
            
            if var updatedGoal = self.currentGoal {
                updatedGoal.currentSteps = self.dailyProgress.reduce(0) { $0 + $1.steps }
                updatedGoal.dailyProgress = self.dailyProgress
                self.currentGoal = updatedGoal
                self.saveCurrentGoal()
            }
        }
    }
    
    private func saveCurrentGoal() {
        guard let goal = currentGoal else { return }
        
        do {
            let encoded = try JSONEncoder().encode(goal)
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        } catch {
            print("Failed to save goal: \(error.localizedDescription)")
        }
    }
    
    private func loadCurrentGoal() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return }
        
        do {
            let goal = try JSONDecoder().decode(StepGoal.self, from: data)
            currentGoal = goal
            dailyProgress = goal.dailyProgress
            loadHistoricalData() // Refresh historical data on load
        } catch {
            print("Failed to load goal: \(error.localizedDescription)")
        }
    }
    
    func resetGoal() {
        currentGoal = nil
        dailyProgress = []
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
}
