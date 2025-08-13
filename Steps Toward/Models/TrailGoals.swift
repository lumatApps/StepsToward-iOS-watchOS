// Full file content for TrailGoals.swift
import Foundation

/// Predefined trail goals.
struct TrailGoals {
    static let oregonTrail = StepGoal(
        name: "Oregon Trail",
        totalSteps: 4_000_000, // ~2,000 miles at 2,000 steps per mile
        description: "Follow the historic 2,170-mile journey from Missouri to Oregon that pioneers took in the 1840s-1860s.",
        startDate: Date()
    )
    
    static let santaFeTrail = StepGoal(
        name: "Santa Fe Trail",
        totalSteps: 1_800_000, // ~900 miles
        description: "Travel the 870-mile commercial highway connecting Missouri and Santa Fe from 1821 to 1880.",
        startDate: Date()
    )
    
    static let californiaTrail = StepGoal(
        name: "California Trail",
        totalSteps: 4_000_000, // ~2,000 miles
        description: "Take the emigrant trail to California used by over 250,000 gold-seekers and farmers.",
        startDate: Date()
    )
    
    static let appalachianTrail = StepGoal(
        name: "Appalachian Trail",
        totalSteps: 4_600_000, // ~2,190 miles
        description: "Hike the entire 2,190-mile footpath through the Appalachian Mountains.",
        startDate: Date()
    )
    
    static let camino = StepGoal(
        name: "Camino de Santiago",
        totalSteps: 1_600_000, // ~800 miles
        description: "Walk the ancient pilgrimage routes leading to Santiago de Compostela in Spain.",
        startDate: Date()
    )
    
    // Additional trails for variety
    static let pacificCrestTrail = StepGoal(
        name: "Pacific Crest Trail",
        totalSteps: 5_300_000, // ~2,650 miles
        description: "Trek from Mexico to Canada along the highest portions of the Sierra Nevada and Cascade mountain ranges.",
        startDate: Date()
    )
    
    static let allTrails: [StepGoal] = [
        oregonTrail, santaFeTrail, californiaTrail, appalachianTrail, camino, pacificCrestTrail
    ]
}
