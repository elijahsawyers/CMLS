//
//  Vector.swift
//  Core Motion Location Services
//
//  Created by Elijah Sawyers on 4/3/19.
//  Copyright © 2019 Elijah Sawyers. All rights reserved.
//

import Foundation

class Vector {
    var x: Double
    var y: Double
    var z: Double
    
    init(_ x: Double, _ y: Double, _ z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    /// The angle between given vectors.
    func dotProduct(vector: Vector) -> Double {
        let numerator = (self.x * vector.x) + (self.y * vector.y) + (self.z * vector.z)
        let denomenator = sqrt((self.x * self.x) + (self.y * self.y) + (self.z * self.z)) * sqrt((vector.x * vector.x) + (vector.y * vector.y) + (vector.z * vector.z))
        return (numerator/denomenator)
    }
}
