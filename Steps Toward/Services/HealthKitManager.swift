//
//  HealthKitManager.swift
//  Steps Toward
//
//  Created by Jared William Tamulynas on 8/12/25.
//

import Foundation
import HealthKit
import Combine
import Observation

@Observable class HealthKitManager {
    private let healthStore = HKHealthStore()
    var todaySteps: Int = 0
    var isAuthorized: Bool = false
    
    init() {
        requestAuthorization()
    }
    
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return
        }
        
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let readTypes: Set<HKObjectType> = [stepType]
        
        healthStore.requestAuthorization(toShare: nil, read: readTypes) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isAuthorized = success
                if success {
                    self?.fetchTodaySteps()
                    self?.observeStepCount()
                } else if let error = error {
                    print("HealthKit authorization failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func fetchTodaySteps() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: now,
            options: .strictStartDate
        )
        
        let query = HKStatisticsQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, result, error in
            guard let result = result,
                  let sum = result.sumQuantity() else {
                DispatchQueue.main.async {
                    self?.todaySteps = 0
                }
                if let error = error {
                    print("Failed to fetch today's steps: \(error.localizedDescription)")
                }
                return
            }
            
            let steps = Int(sum.doubleValue(for: HKUnit.count()))
            DispatchQueue.main.async {
                self?.todaySteps = steps
            }
        }
        
        healthStore.execute(query)
    }
    
    func fetchStepsForDate(_ date: Date, completion: @escaping (Int) -> Void) {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )
        
        let query = HKStatisticsQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, error in
            guard let result = result,
                  let sum = result.sumQuantity() else {
                completion(0)
                if let error = error {
                    print("Failed to fetch steps for date \(date): \(error.localizedDescription)")
                }
                return
            }
            
            let steps = Int(sum.doubleValue(for: HKUnit.count()))
            completion(steps)
        }
        
        healthStore.execute(query)
    }
    
    private func observeStepCount() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        let query = HKObserverQuery(sampleType: stepType, predicate: nil) { [weak self] _, _, error in
            if let error = error {
                print("Step count observer failed: \(error.localizedDescription)")
                return
            }
            self?.fetchTodaySteps()
        }
        
        healthStore.execute(query)
        healthStore.enableBackgroundDelivery(for: stepType, frequency: .hourly) { success, error in
            if !success, let error = error {
                print("Failed to enable background delivery: \(error.localizedDescription)")
            }
        }
    }
}
