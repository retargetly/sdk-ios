//
//  CLLocationManagerDelegate+Retargetly.swift
//  Retargetly
//
//  Created by José Valderrama on 8/31/17.
//  Copyright © 2017 NextDots. All rights reserved.
//

import CoreLocation
import Foundation

extension CLLocationManagerDelegate {
    // MARK: - Method Swizzling
    
//    func ret_locationManager(_ manager: CLLocationManager,
//                               didChangeAuthorization status: CLAuthorizationStatus) {
////        self.ret_viewDidAppear(animated: animated)
////        RManager.default.track(et: .change, value: String(describing: self.classForCoder))
//    }
}

extension CLLocationManager {
    public class var isServiceUsable: Bool {
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
    
    @objc func ret_startUpdatingLocation() {
        self.ret_startUpdatingLocation()
        if let coordinate = location?.coordinate, CLLocationManager.isServiceUsable {
            let formattedCoordinate = "\(coordinate.latitude);\(coordinate.longitude)"
            let value = [REventParam.rPosition.rawValue: formattedCoordinate]
            RManager.default.track(et: .custom, value: value)
        }
    }
}

//public class RCLLocationManagerDelegate: NSObject, CLLocationManagerDelegate {
//    
//    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
//        print("didChangeAuthorization", status.rawValue)
//    }
//    
//    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
//        print("didFailWithError", error)
//    }
//    
//    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        print("didUpdateLocations", locations)
//    }
//}

