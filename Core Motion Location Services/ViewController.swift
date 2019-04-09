//
//  ViewController.swift
//  Core Motion Example
//
//  Created by Elijah Sawyers on 4/1/19.
//  Copyright © 2019 Elijah Sawyers. All rights reserved.
//

import UIKit
import CoreMotion
import CoreLocation

class ViewController: UIViewController {
    
    @IBOutlet weak var displacement: UILabel!
    @IBOutlet weak var log: UITextView!
    
    /// Manages all Core Motion services.
    let cmManager = CMMotionManager()
    
    /// Used to grab phone heading.
    let clManager = CLLocationManager()
    
    /// The time intervals between pulling accelerometer data.
    let updateInterval = 0.01
    
    /// The user's average walking speed.
    var averageVelocity: Double?
    
    /// The user's average walking velocities pulled during configuration.
    var averageVelocities: [Double] = [] {
        didSet {
            if averageVelocities.count == 3 {
                averageVelocity = (averageVelocities[0] + averageVelocities[1] + averageVelocities[2])/3.0
                log.text += "Finished config with avg velocity: \(averageVelocity!)m/s \n"
                
                for i in 0..<3 {
                    avgWMAs[i] /= 100
                }
                avgWMA = (avgWMAs[0] + avgWMAs[1] + avgWMAs[2])/3.0
                log.text += "Finished config with avg wma: \(avgWMA!)m/s \n"
            }
        }
    }
    
    /// The average wma during configuration.
    var avgWMA: Double?
    
    /// The average wmas during configuration.
    var avgWMAs: [Double] = Array(repeating: 0.0, count: 3)
    
    /// Is the user configuring the app?
    var configuring = false
    
    /// The time for one configuration interval.
    var configTime = 0.0
    
    /// Timer to configure the user's walking speed.
    var configurationTimer: Timer?
    
    /// Stores the user's displacement.
    var userDisplacement = 0.0
    
    /// Is the user tracking their walking?
    var walking = false
    
    var walkingTimer: Timer?
    
    var displacementTimer: Timer?
    
    var stopLogging = true

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize the Core Motion package.
        cmManager.deviceMotionUpdateInterval = updateInterval
        cmManager.startDeviceMotionUpdates()
        
        // Initialize the Core Location package.
        clManager.headingFilter = 45.0
        clManager.startUpdatingHeading()
    }
    
    func weightedMovingAverage(values: [Double]) -> Double {
        var numerator = 0.0
        var denomenator = 0.0
        
        for i in 0..<values.count {
            numerator += Double(i + 1) * values[i]
            denomenator += Double(i + 1)
        }
        
        return (numerator/denomenator)
    }
    
    /// Used to start the configuration process.
    @IBAction func config(_ sender: UIButton) {
        if !configuring {
            log.text += "Walk 4 meters, and press the config button again when done!\n"
            
            // Previous acceleration.
            var previousAcceleration: Vector?
            
            // To try to eliminate "noise," we use a moving average for the angle between current and previous acceleration vectors.
            var thetaValues: [Double] = Array(repeating: 0.0, count: 100)
            
            // Pull accelerometer data for configuration.
            configurationTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] timer in
                // Increase congig time each interval.
                self!.configTime += self!.updateInterval
                
                // Grab the motion information.
                let accelerationData = self!.cmManager.deviceMotion?.userAcceleration
                
                // Grab the acceleration vector.
                if let x = accelerationData?.x, let y = accelerationData?.y, let z = accelerationData?.z {
                    // Convert G's to m/s^2, and assign it to a vector.
                    let currentAcceleration = Vector(
                        x * 9.81,
                        y * 9.81,
                        z * 9.81
                    )
                    
                    // Calculate the angle between the current and previous acceleration vector.
                    var theta: Double
                    if previousAcceleration != nil {
                        theta = currentAcceleration.dotProduct(vector: previousAcceleration!)
                    } else {
                        // Set current acceleration to the previous acceleration.
                        previousAcceleration = currentAcceleration
                        return
                    }
                    
                    // Append the current angle and remove the oldest.
                    thetaValues.removeFirst()
                    thetaValues.append(theta)
                    
                    // Compute the average wma during the 1->2 seconds.
                    if self!.configTime >= 1.0 && self!.configTime <= 2.0 {
                        self!.avgWMAs[self!.averageVelocities.count] += abs(self!.weightedMovingAverage(values: thetaValues))
                    }
                    
                    // Set current acceleration to the previous acceleration.
                    previousAcceleration = currentAcceleration
                }
            }
            
            configuring = true
        } else {
            configurationTimer!.invalidate()
            configurationTimer = nil
            
            log.text += "You walked \(4.0 / configTime)m/s!\n"
            
            averageVelocities.append(4.0 / configTime)
            
            configuring = false
            configTime = 0.0
        }
    }
    
    @IBAction func walk(_ sender: Any) {
        stopLogging = !stopLogging
        
        if stopLogging {
            walkingTimer?.invalidate()
            return
        }
        
        log.text = ""
        
        // Create ML model to predict whether or not the user is walking.
        let model = Walking()
        
        // Iteration.
        var i = 0
        
        // Previous acceleration.
        var previousAcceleration: Vector?
        
        // Keep track of time above 0.8.
        var timeAbove = 0.0
        
        // Has the wma been above 0.8 for more than one second?
        var timeAboveOneSec = 0.0
        
        // Walking?
        var walking = false
        
        // Timer to update displacement, if the user is walking.
        var displacementTimer: Timer?
        
        // To try to eliminate "noise," we use a moving average for the angle between current and previous acceleration vectors.
        var thetaValues: [Double] = Array(repeating: 0.0, count: 100)
        
        walkingTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] timer in
            // Grab the motion information.
            let accelerationData = self!.cmManager.deviceMotion?.userAcceleration
            
            // Grab the acceleration vector.
            if let x = accelerationData?.x, let y = accelerationData?.y, let z = accelerationData?.z {
                // Convert G's to m/s^2, and assign it to a vector.
                let currentAcceleration = Vector(
                    x * 9.81,
                    y * 9.81,
                    z * 9.81
                )
                
                // Calculate the angle between the current and previous acceleration vector.
                var theta: Double
                if previousAcceleration != nil {
                    theta = currentAcceleration.dotProduct(vector: previousAcceleration!)
                } else {
                    // Set current acceleration to the previous acceleration.
                    previousAcceleration = currentAcceleration
                    return
                }
                
                // Append the current angle and remove the oldest.
                thetaValues.removeFirst()
                thetaValues.append(theta)
                
                // Keep up with wma time above 0.8
                if abs(self!.weightedMovingAverage(values: thetaValues)) > 0.8 {
                    timeAbove += self!.updateInterval
                    if timeAbove >= 1.0 {
                        timeAboveOneSec = 1.0
                    } else {
                        timeAboveOneSec = 0.0
                    }
                } else {
                    timeAbove = 0.0
                    timeAboveOneSec = 0.0
                }
                
                // Is the user walking?
                guard let walkingPrediction = try? model.prediction(wma: abs(self!.weightedMovingAverage(values: thetaValues)), time_above: timeAbove, time_above_1: timeAboveOneSec) else {
                    return
                }
                
                // If the user is walking...
                if walkingPrediction.walking == 1 {
                    //...and wasn't previously walking...
                    if !walking {
                        //...set the walking flag...
                        walking = true
                        
                        //...update displacement...
                        self!.userDisplacement += self!.averageVelocity!
                        
                        //...and start a timer to update displacement every 1.0s.
                        displacementTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
                            self!.userDisplacement += self!.averageVelocity!
                            self!.displacement.text = String(self!.userDisplacement)
                        }
                        displacementTimer!.fire()
                    }
                } else {
                    // If the user isn't walking, invalidate the displacement timer, if need be, and set the walking flag to false.
                    displacementTimer?.invalidate()
                    walking = false
                }
                
                // Set current acceleration to the previous acceleration.
                previousAcceleration = currentAcceleration
                
                // Log information.
                let values = String(i) + ", " + String(abs(self!.weightedMovingAverage(values: thetaValues))) + "\n"
                self!.log.text = values + self!.log.text
                i += 1
            }
        }
        
        walkingTimer!.fire()
    }
    
}
