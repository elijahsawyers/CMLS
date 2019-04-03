//
//  ViewController.swift
//  Core Motion Example
//
//  Created by Elijah Sawyers on 4/1/19.
//  Copyright © 2019 Elijah Sawyers. All rights reserved.
//

import UIKit
import CoreMotion

class ViewController: UIViewController {
    
    @IBOutlet weak var displacement: UILabel!
    @IBOutlet weak var log: UITextView!
    
    /// Manages all Core Motion services.
    let cmManager = CMMotionManager()
    
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
            }
        }
    }
    
    /// Is the user configuring the app?
    var configuring = false
    
    /// The time for one configuration interval.
    var configTime = 0.0
    
    /// Avgerage acceleration during configuration.
    var averageAcceleration = 0.0
    
    /// The user's average accelerations pulled during configuration.
    var averageAccelerations: [Double] = [] {
        didSet {
            if averageAccelerations.count == 3 {
                averageAcceleration = (averageAccelerations[0] + averageAccelerations[1] + averageAccelerations[2])/3.0
                log.text += "The average acceleration was \(averageAcceleration)\n"
                log.text += "Press Walk to track distance\n"
            } else {
                averageAcceleration = 0.0
            }
        }
    }
    
    /// Timer to configure the user's walking speed.
    var configurationTimer: Timer?
    
    /// Stores the user's displacement.
    var userDisplacement = 0.0
    
    /// Is the user tracking their walking?
    var walking = false
    
    /// Holds timer that tracks walking.
    var walkingTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize the Core Motion package.
        cmManager.deviceMotionUpdateInterval = updateInterval
        cmManager.startDeviceMotionUpdates()
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
            
            // Pull accelerometer data for configuration.
            configurationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
                self!.configTime += 0.1
                
                // Grab the acceleration information.
                let deviceMotion = self!.cmManager.deviceMotion
                
                // Grab the user's acceleration.
                if let phoneYAccel = deviceMotion?.userAcceleration.y {
                    // Convert G's to m/s^2.
                    self!.averageAcceleration += (abs(phoneYAccel) * 9.81)
                }
            }
            
            configuring = true
        } else {
            configurationTimer!.invalidate()
            configurationTimer = nil
            
            log.text += "You walked \(4.0 / configTime)m/s!\n"
            
            averageVelocities.append(4.0 / configTime)
            averageAccelerations.append(averageAcceleration/(configTime/0.1))
            
            configuring = false
            configTime = 0.0
        }
    }
    
    @IBAction func walk(_ sender: Any) {
        log.text = ""
        
        // Walking.
        var walking = false
        
        // Previous acceleration.
        var previousAcceleration: Vector?
        
        // Iterations over 0.8 wma.
        var iOverWma = 0
        
        // Iterations under 0.8 wma.
        var iUnderWma = 0
        
        // To try to eliminate "noise," we use a moving average for the angle between current and previous acceleration vectors.
        var thetaValues: [Double] = Array(repeating: 0.5, count: 50)
        
        let timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] timer in
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
                
                // Give the accelerometer at least one second to grab data.
                if walking {
                    self!.userDisplacement += self!.averageVelocity! * self!.updateInterval
                    self!.displacement.text = String(self!.userDisplacement)
                    
                    //self!.displacement.text = "Walking"

                    // Watch for a long spike in deceleration because it means the user has stopped walking.
                    if abs(self!.weightedMovingAverage(values: thetaValues)) < 0.825 {
                        iUnderWma += 1
                        if iUnderWma >= 5 {
                            walking = false
                            //self!.displacement.text = "Not Walking"
                        }
                    } else {
                        iUnderWma = 0
                    }
                } else {
                    // Watch for a long spike in acceleration because it means the user has started walking.
                    if abs(self!.weightedMovingAverage(values: thetaValues)) > 0.825 {
                        iOverWma += 1
                        if iOverWma >= 25 {
                            self!.userDisplacement += self!.averageVelocity! * 0.25
                            self!.displacement.text = String(self!.userDisplacement)
                            walking = true
                        }
                    } else {
                        iOverWma = 0
                    }
                }
                
                // Set current acceleration to the previous acceleration.
                previousAcceleration = currentAcceleration
                
                // Log information.
                let values = String(iOverWma) + ", " + String(abs(self!.weightedMovingAverage(values: thetaValues))) + "\n"
                self!.log.text = values + self!.log.text
            }
        }
        
        timer.fire()
    }
    
}
