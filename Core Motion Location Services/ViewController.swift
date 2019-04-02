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
    @IBOutlet weak var userAccel: UILabel!
    
    /// Manages all Core Motion services.
    let cmManager = CMMotionManager()
    
    /// Previous velocity.
    var previousVelocity = 0.0
    
    /// Current velocity.
    var currentVelocity = 0.0
    
    /// Previous acceleration.
    var previousAcceleration = 0.0
    
    /// Current acceleration.
    var currentAcceleration = 0.0
    
    /// Stores the user's displacement.
    var userDisplacement = 0.0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // The time intervals between pulling accelerometer data.
        let updateInterval = 0.01
        
        // The number of intervals to run before averaging the accelerations and updating the user displacement.
        let numberOfIntervals = 100
        
        // Initialize the Core Motion package.
        cmManager.deviceMotionUpdateInterval = updateInterval
        cmManager.startDeviceMotionUpdates()
        
        // Keep track of which iteration we're currently on.
        var iter = 0
        
        // Store the average acceleration over the course of X amount of intervals.
        var avgAccel = 0.0
        
        let timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] timer in
            // Grab the acceleration information.
            let deviceMotion = self!.cmManager.deviceMotion
            
            // Phone acceleration in the "y" direction.
            var yAccel = 0.0
            
            if let phoneYAccel = deviceMotion?.userAcceleration.y {
                // Convert G's to m/s^2.
                yAccel = phoneYAccel * 9.81
                
                // Values less than 0.3 are "junk values" (i.e. the user isn't moving).
                if yAccel >= 0.30 {
                    if iter >= numberOfIntervals {
                        // Set the current acceleration and velocity.
                        self!.currentAcceleration = (avgAccel/Double(numberOfIntervals))
                        self!.currentVelocity = (avgAccel/Double(numberOfIntervals)) * updateInterval
                        
                        // Update user displacement.
                        self!.updateDisplacement(pV: self!.previousVelocity, cA: self!.currentAcceleration, t: 1.0)
                        
                        // Update previous velocity to be the current velocity.
                        self!.previousVelocity = self!.currentVelocity
                        
                        // Reset the itereration data.
                        iter = 0
                        //avgAccel = 0.0
                    } else {
                        // Update the itereration data.
                        iter += 1
                        avgAccel += yAccel
                    }
                }
            }
            
            // Monitor acceleration.
            self!.userAccel.text = "Y: " + String(yAccel)
            
            // Monitor acceleration.
            self!.displacement.text = String(self!.userDisplacement)
            
        }
        timer.fire()
    }
    
    func updateDisplacement(pV: Double, cA: Double, t: Double) {
        userDisplacement += (pV * t) + (0.5 * cA * (t * t))
    }

}

