//
//  Copyright (c) 2015年 NY. All rights reserved.
//

import HealthKit

class HKManager: NSObject {
    
    var store: HKHealthStore!
    
    class var sharedManager: HKManager {
        struct Singleton {
            static let instance = HKManager()
        }
        return Singleton.instance
    }
    
    // MARK: - 💖 生命周期 (Lifecycle)
    private override init() {
        super.init()
        store = HKHealthStore()
    }
    
    func storeTemperature(date: NSDate, value: Double, location: HKBodyTemperatureSensorLocation = .Body) { // 体温
        let sample = HKQuantitySample(
            type: HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyTemperature),
            quantity: HKQuantity(unit: HKUnit.degreeCelsiusUnit(), doubleValue: value), // 永远存摄氏
            startDate: date,
            endDate: date,
            metadata: [HKMetadataKeyBodyTemperatureSensorLocation : location.rawValue]
        )
        store.saveObject(sample, withCompletion: nil)
    }
    
    func storeHeartRate(date: NSDate, value: Double) { // 心率
        let unit = HKUnit.countUnit().unitDividedByUnit(HKUnit.minuteUnit()) // 每分钟
        let sample = HKQuantitySample(
            type: HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate),
            quantity: HKQuantity(unit: unit, doubleValue: value),
            startDate: date,
            endDate: date
        )
        store.saveObject(sample, withCompletion: nil)
    }
    
    func readMostRecentSample(sampleType: HKSampleType, completion: ((HKSample!, NSError!) -> Void)!)
    {
        // 1. Build the Predicate
        let past = NSDate.distantPast() as NSDate
        let now = NSDate()
        let mostRecentPredicate = HKQuery.predicateForSamplesWithStartDate(past, endDate:now, options: .None)
        // 2. Build the sort descriptor to return the samples in descending order
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        // 3. we want to limit the number of samples returned by the query to just 1 (the most recent)
        let limit = 1 // 数量
        // 4. Build samples query
        let sampleQuery = HKSampleQuery(sampleType: sampleType, predicate: mostRecentPredicate, limit: limit, sortDescriptors: [sortDescriptor])
            { (sampleQuery, results, error) in
                if let queryError = error {
                    completion(nil, error)
                    return
                }
                // Get the first sample
                let mostRecentSample = results.first as? HKQuantitySample
                // Execute the completion closure
                if completion != nil {
                    completion(mostRecentSample,nil)
                }
        }
        store.executeQuery(sampleQuery) // 执行查询
    }
}
