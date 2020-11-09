//
//  CLLocationManagerDelegate+Retargetly.swift
//  Retargetly
//
//  Created by José Valderrama on 8/31/17.
//  Copyright © 2017 Retargetly. All rights reserved.
//

import CoreLocation
import Foundation

extension CLLocationManager {
    /// Use this var to check if service is usable. It means, the service is active, and ready to use.
    @objc public class var isServiceUsable: Bool {
        guard CLLocationManager.locationServicesEnabled() else {
            return false
        }
        
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways, .authorizedWhenInUse:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Method Swizzling
    
    @objc func ret_startUpdatingLocation() {
        self.ret_startUpdatingLocation()
        RManager.default.rLocationManager?.startGPSTrackTimer()
    }
}
