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
    let updateInterval = 0.1
    
    /// The user's average walking speed.
    var averageVelocity: Double?
    
    /// The user's average walking velocities.
    var averageVelocities: [Double] = [] {
        didSet {
            if averageVelocities.count == 3 {
                averageVelocity = (averageVelocities[0] + averageVelocities[1] + averageVelocities[2])/3.0
                log.text += "Finished config with avg velocity: \(averageVelocity!)m/s \n"
                log.text += "Press Walk to track distance"
            }
        }
    }
    
    /// Is the user configuring?
    var configuring = false
    
    /// The configuration time.
    var configTime = 0.0
    
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
    
    @IBAction func config(_ sender: UIButton) {
        if !configuring {
            log.text += "Walk 4 meters, and press the config button again when done!\n"
            
            configurationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
                self!.configTime += 0.1
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
    
    @IBAction func updatePosition(_ sender: UIButton) {
        
        walking = !walking
        
        if walking {
            userDisplacement = 0.0
            walkingTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] timer in
                // Grab the acceleration information.
                let deviceMotion = self!.cmManager.deviceMotion
                
                // Phone acceleration in the "y" direction.
                var yAccel = 0.0
                
                // Grab the user's acceleration.
                if let phoneYAccel = deviceMotion?.userAcceleration.y {
                    // Convert G's to m/s^2.
                    yAccel = phoneYAccel * 9.81
                    
                    // Values less than 0.5 are "junk values" (i.e. the user isn't moving).
                    if abs(yAccel) >= 0.35 {
                        self!.log.text = "Now walking!\n"
                        self!.userDisplacement += (self!.updateInterval * self!.averageVelocity!)
                    } else {
                        self!.log.text = "No longer walking!\n"
                    }
                }
                
                // Monitor acceleration.
                self!.displacement.text = String(self!.userDisplacement)
            }
        } else {
            walkingTimer?.invalidate()
            userDisplacement = 0.0
        }
    }
    
    func updateDisplacement(pV: Double, cA: Double, t: Double) {
        userDisplacement += (pV * t) + (0.5 * cA * (t * t))
    }

}

