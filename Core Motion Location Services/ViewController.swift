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
    
    /// Outlet to the label that display's displacement in meters.
    @IBOutlet weak var displacement: UILabel!
    
    /// Outlet to the log of walking data.
    @IBOutlet weak var log: UITextView!
    
    /// Manages all Core Motion services.
    let cmManager = CMMotionManager()
    
    /// The time intervals between receiving accelerometer data.
    let updateInterval = 0.01
    
    /// The user's average walking speed, based on world average.
    var averageVelocity = 1.25
    
    /// Stores the user's displacement, in meters.
    var userDisplacement = 0.0
    
    /// Is the user currently walking?
    var walking = false
    
    /// When the walk button is pressed, this timer receives IMU updates.
    var imuInterval: Timer?
    
    /// Updates the user's displacement, if walking.
    var walkingTimer: Timer?
    
    /// When the walk button is pressed a second time, it stops the flow of walking data so that it can be pulled.
    var stopLogging = true

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize the Core Motion package.
        cmManager.deviceMotionUpdateInterval = updateInterval
        cmManager.startDeviceMotionUpdates()
    }
    
    /**
     *  Finds the weighted moving average of an array of doubles.
     *  - parameter values: An array of doubles to find the weighted moving average.
     */
    func weightedMovingAverage(values: [Double]) -> Double {
        var numerator = 0.0
        var denomenator = 0.0
        
        for i in 0..<values.count {
            numerator += Double(i + 1) * values[i]
            denomenator += Double(i + 1)
        }
        
        return (numerator/denomenator)
    }
    
    /// When the walk button is pressed, log walking data, and update user displacement.
    @IBAction func walk(_ sender: Any) {
        stopLogging = !stopLogging
        
        if stopLogging {
            imuInterval?.invalidate()
            return
        }
        
        // Create ML model to predict whether or not the user is walking.
        let model = Walking()
        
        // Current iteration.
        var i = 0
        
        // Previous acceleration.
        var previousAcceleration: Vector?
        
        // Keep track of time above 0.8.
        var timeAbove = 0.0
        
        // Has the wma been above 0.8 for more than one second?
        var timeAboveOneSec = 0.0
        
        // Is the user walking?
        var walking = false
        
        // Timer to update displacement, if the user is walking.
        var walkingTimer: Timer?
        
        // To try to eliminate "noise," we use a moving average for the angle between current and previous acceleration vectors.
        var thetaValues: [Double] = Array(repeating: 0.0, count: 100)
        
        imuInterval = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] timer in
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
                
                // Keep up with wma time above 0.8.
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
                
                // Use the ML model to determine if the user is walking.
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
                        self!.userDisplacement += self!.averageVelocity
                        
                        //...and start a timer to update displacement every 1.0s.
                        walkingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
                            self!.userDisplacement += self!.averageVelocity
                            self!.displacement.text = String(self!.userDisplacement)
                        }
                        walkingTimer!.fire()
                    }
                } else {
                    // If the user isn't walking, invalidate the displacement timer, if need be, and set the walking flag to false.
                    walkingTimer?.invalidate()
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
        
        imuInterval!.fire()
    }
    
}
