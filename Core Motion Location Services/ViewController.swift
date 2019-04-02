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
        
        cmManager.deviceMotionUpdateInterval = 0.01
        cmManager.startDeviceMotionUpdates()
        
        var iter = 0
        var avgAccel = 0.0
        
        let timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] timer in
            let deviceMotion = self!.cmManager.deviceMotion
            var y = 0.0;
            
            if let usrY = deviceMotion?.userAcceleration.y {
                y = usrY * 9.81
                
                // Values less than 0.3 are "garbage." (i.e. the user isn't moving)
                if y > 0.5 {
                    if iter >= 100 {
                        iter = 0
                        self!.currentAcceleration = (avgAccel/100.0)
                        self!.currentVelocity = (avgAccel/100.0) * 1
                        self!.updateDisplacement(pV: self!.previousVelocity, cA: self!.currentAcceleration, t: 1.0)
                        self!.previousVelocity = self!.currentVelocity
                    } else {
                        iter += 1
                        avgAccel += y
                    }
                }
            }
            
            
            // Monitor acceleration.
            self!.userAccel.text = "Y: " + String(y)
            
            // Monitor acceleration.
            self!.displacement.text = String(self!.userDisplacement)
            
        }
        timer.fire()
    }
    
    func updateDisplacement(pV: Double, cA: Double, t: Double) {
        userDisplacement += (pV * t) + (0.5 * cA * (t * t))
    }

}

