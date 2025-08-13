// Full updated content for HomeView.swift
import SwiftUI

struct HomeView: View {
    @State private var stepGoalManager = StepGoalManager()
    @State private var showingGoalSelection = false
    @State private var showingCompletion = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                if let goal = stepGoalManager.currentGoal {
                    ScrollView {
                        VStack(spacing: 24) {
                            GoalHeaderView(goal: goal)
                            
                            ProgressTrailView(goal: goal)
                            
                            TodayStepsView()
                            
                            if !stepGoalManager.dailyProgress.isEmpty {
                                RecentProgressView(progress: Array(stepGoalManager.dailyProgress.suffix(7)))
                            }
                            
                            Spacer(minLength: 100)
                        }
                        .padding()
                    }
                } else {
                    VStack(spacing: 30) {
                        Image(systemName: "figure.walk.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(Color.accent)
                            .symbolEffect(.bounce, value: showingGoalSelection)
                        
                        VStack(spacing: 16) {
                            Text("Welcome to Steps Toward!")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("Choose a trail and start your journey. Track your steps and achieve your fitness goals!")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.secondary)
                        }
                        
                        Button {
                            showingGoalSelection = true
                        } label: {
                            HStack {
                                Image(systemName: "map")
                                Text("Choose Your Trail")
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding()
                            .background(Color.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Steps Toward")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if stepGoalManager.currentGoal != nil {
                            stepGoalManager.resetGoal()
                        }
                        showingGoalSelection = true
                    } label: {
                        Image(systemName: stepGoalManager.currentGoal != nil ? "gearshape" : "plus")
                    }
                }
            }
            .sheet(isPresented: $showingGoalSelection) {
                GoalSelectionView(stepGoalManager: stepGoalManager)
            }
        }
        .onAppear {
            if stepGoalManager.currentGoal != nil {
                stepGoalManager.loadHistoricalData()
            }
        }
        .onChange(of: stepGoalManager.currentGoal?.isCompleted) { oldValue, newValue in
            if newValue == true {
                showingCompletion = true
            }
        }
        .fullScreenCover(isPresented: $showingCompletion) {
            if let goal = stepGoalManager.currentGoal {
                CompletionCelebrationView(goal: goal)
            }
        }
    }
}

#Preview {
    HomeView()
}
