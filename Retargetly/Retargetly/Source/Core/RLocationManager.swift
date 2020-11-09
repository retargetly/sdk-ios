//
//  RLocationManager.swift
//  Retargetly
//
//  Created by José Valderrama on 17/06/2018.
//  Copyright © 2018 Retargetly. All rights reserved.
//

import Foundation
import CoreLocation

@objc public protocol RLocationManagerDelegate: class {
    /// Mirror for same method didUpdateLocations: on CLLocationManager
    @objc optional func rLocationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    /// Mirror for same method didFailWithError: on CLLocationManager
    @objc optional func rlocationManager(_ manager: CLLocationManager, didFailWith error: Error)
    @objc optional func rLocationManager(_ manager: CLLocationManager, couldNotInitBecause error: NSError?)
}

/**
 Retargetly Location Service manager, allows to track GPS values.
 */
@objcMembers public class RLocationManager: NSObject {
    
    typealias TimerCallback = () -> Void
    
    /// Motion values
    private enum RMotionValue: String {
        /// Root value for motion values
        case rootValue = "response"
        /// Motion frequency
        case motionFrequency = "motionFrequency"
        /// Static frequency
        case staticFrequency = "staticFrequency"
        /// Motion detection frequency
        case motionDetectionFrequency = "motionDetectionFrequency"
        /// Motion threshold
        case motionThreshold = "motionThreshold"
    }
    
    /// Motion states
    fileprivate enum RMotionState {
        case inMotion
        case noEnoughtMotion
        case unknown
    }
    
    // SDK Default values
    private static let kMotionFrequency: TimeInterval = 300
    private static let kStaticFrequency: TimeInterval = 180
    private static let kMotionDetectionFrequency: TimeInterval = 120
    private static let kMotionThreshold: CLLocationDistance = 300
    
    // MARK: - Instance values
    /// Time frequency to send GPS while in motion
    fileprivate let motionFrequency: TimeInterval
    /// Time frequency to send GPS while in repose
    fileprivate let staticFrequency: TimeInterval
    /// Time frequency to check if device motion state (uses 'motionThreshold' property)
    fileprivate let motionDetectionFrequency: TimeInterval
    /// Distance to be in 'in motion' state
    fileprivate let motionThreshold: CLLocationDistance
    /// Device is in motion state by bussines logic criteria
    fileprivate var motionState: RMotionState = .unknown {
        didSet {
            if oldValue != motionState {
                startStateTrackTimer()
            }
            
            RManager.default.delegate?.rManager?(RManager.default, didSendActionWith: "motionState \(motionState)")
        }
    }
    
    // MARK: - CoreLocation
    /// CoreLocation location manager
    public private(set) var locationManager: CLLocationManager!
    
    /// Retargetly location delegate
    public weak var delegate: RLocationManagerDelegate?
    /// Last location received
    fileprivate var lastLocation: CLLocation? = nil
    
    // Timers
    fileprivate var gpsTrackTimer: Timer?
    fileprivate var stateTrackTimer: Timer?
    private var stateTrackTimerInterval: TimeInterval {
        switch motionState {
        case .inMotion:
            return motionFrequency
        case .noEnoughtMotion:
            return staticFrequency
        default:
            return -1
        }
    }
    
    override public var description: String {
        return "motionFrequency: \(motionFrequency) - staticFrequency: \(staticFrequency) -  motionDetectionFrequency: \(motionDetectionFrequency) -  motionThreshold: \(motionThreshold) "
    }
    
    // MARK: - Initialization
    
    convenience init(from serverValues: JSON?) {
        guard let serverValues = serverValues,
            let rootValue = serverValues[RMotionValue.rootValue.rawValue] as? JSON,
        let motionFrequency = rootValue[RMotionValue.motionFrequency.rawValue] as? TimeInterval,
        let staticFrequency = rootValue[RMotionValue.staticFrequency.rawValue] as? TimeInterval,
        let motionDetectionFrequency = rootValue[RMotionValue.motionDetectionFrequency.rawValue] as? TimeInterval,
        let motionThreshold = rootValue[RMotionValue.motionThreshold.rawValue] as? CLLocationDistance
        else {
            self.init()
            return
        }
        
        self.init(motionFrequency: motionFrequency,
                  staticFrequency: staticFrequency,
                  motionDetectionFrequency: motionDetectionFrequency,
                  motionThreshold: motionThreshold)
    }
    
    private init(motionFrequency: TimeInterval = kMotionFrequency,
                 staticFrequency: TimeInterval = kStaticFrequency,
                 motionDetectionFrequency: TimeInterval = kMotionDetectionFrequency,
                 motionThreshold: CLLocationDistance = kMotionDetectionFrequency) {
        
        self.motionFrequency = motionFrequency
        self.staticFrequency = staticFrequency
        self.motionDetectionFrequency = motionDetectionFrequency
        self.motionThreshold = motionThreshold
        
        super.init()
        self.configureCLLocationManager()
        self.askLocationServiceIfNeeded()
    }
    
    /// Configures the CLLocationManager inside RLocationManager
    /// This method checks if UIBackgroundModes:location is enable in info.plist file
    private func configureCLLocationManager() {
        DispatchQueue.main.sync { [weak self] in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.locationManager = CLLocationManager()
            strongSelf.locationManager.delegate = self
            strongSelf.locationManager.desiredAccuracy = kCLLocationAccuracyBest
            strongSelf.locationManager.distanceFilter = kCLDistanceFilterNone
            strongSelf.locationManager.pausesLocationUpdatesAutomatically = false
            strongSelf.lastLocation = strongSelf.locationManager.location
            
            // Only if has background mode for location service
            guard let info = Bundle.main.infoDictionary,
            let backgroundModes = info["UIBackgroundModes"] as? [String : Any],
                let _ = backgroundModes["location"] else {
                    return
            }
            
            if #available(iOS 9.0, *) {
                strongSelf.locationManager.allowsBackgroundLocationUpdates = true
            }
        }
    }
    
    /// Ask for location services authorization only if needed
    private func askLocationServiceIfNeeded() {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else {
                return
            }
            
            let manager = RManager.default
            
            // If forceGPS is required and location services are enabled
            if manager.forceGPS {
                if CLLocationManager.locationServicesEnabled() {
                    strongSelf.locationManager.requestAlwaysAuthorization()
                } else {
                    strongSelf.delegate?.rLocationManager?(strongSelf.locationManager, couldNotInitBecause: NSError.errorFromRetargetlyError(.locationServiceNotAllowedOrDenied))
                }
            }
        }
    }
    
    // MARK: - Track GPS
    
    func startGPSTrackTimer(_ callback: TimerCallback? = nil) {
        askLocationServiceIfNeeded()
        
        // Operates only if track timer is nil
        guard self.gpsTrackTimer == nil, RManager.default.sendGeoData else {
            return
        }
        
        self.stopTracking {
            // Creates and schedule the new track timer
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self,
                      let locationManager = strongSelf.locationManager else {
                    return
                }
                
                strongSelf.sendTrackedLocation()
                strongSelf.gpsTrackTimer = Timer.scheduledTimer(timeInterval: strongSelf.motionDetectionFrequency, target: locationManager, selector: #selector(locationManager.startUpdatingLocation), userInfo: nil, repeats: true)
                locationManager.startUpdatingLocation()
                
                callback?()
            }
        }
    }
    
    private func stopGPSTrackTimer(_ callback: TimerCallback? = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.gpsTrackTimer?.invalidate()
            strongSelf.gpsTrackTimer = nil
            callback?()
        }
    }
    
    func startStateTrackTimer(_ callback: TimerCallback? = nil) {
        guard self.motionState != .unknown, RManager.default.sendGeoData else {
            return
        }
        
        self.stopStateTrackTimer {
            // Creates and schedule the new track timer
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self, strongSelf.stateTrackTimerInterval != -1 else {
                    return
                }
                
                strongSelf.stateTrackTimer = Timer.scheduledTimer(timeInterval: strongSelf.stateTrackTimerInterval, target: strongSelf, selector: #selector(strongSelf.sendTrackedLocation), userInfo: nil, repeats: true)
                
                callback?()
            }
        }
    }
    
    private func stopStateTrackTimer(_ callback: TimerCallback? = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.stateTrackTimer?.invalidate()
            strongSelf.stateTrackTimer = nil
            callback?()
        }
    }
    
    func stopTracking(_ callback: TimerCallback? = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.locationManager.stopUpdatingLocation()
            strongSelf.stopGPSTrackTimer()
            strongSelf.stopStateTrackTimer()
            strongSelf.motionState = .unknown
            callback?()
        }
    }
    
    // MARK: - Location Functionality
    
    fileprivate func doLocationFunctionality(with newLocation: CLLocation) {
        guard let lastLocation = self.lastLocation else {
            self.lastLocation = newLocation
            return
        }
        
        let distance = lastLocation.distance(from: newLocation)
        RManager.default.delegate?.rManager?(RManager.default, didSendActionWith: "Covered meters: \(distance)")
        
        if distance >= self.motionThreshold {
            self.lastLocation = newLocation
            self.motionState = .inMotion
        } else {
            self.motionState = .noEnoughtMotion
        }
    }
    
    @objc private func sendTrackedLocation() {
        RManager.default.track(et: .geo, value: nil)
        RManager.default.delegate?.rManager?(RManager.default, didSendActionWith: "GEO EVENT - Sent type \(self.motionState)")
    }
}

// MARK: - CLLocationManagerDelegate

extension RLocationManager: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.locationManager.stopUpdatingLocation()
        delegate?.rLocationManager?(manager, didUpdateLocations: locations)
        
        // Has a new location
        if let lastLocationReceived = locations.last {
            self.doLocationFunctionality(with: lastLocationReceived)
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.stopTracking()
        delegate?.rlocationManager?(manager, didFailWith: error)
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if !CLLocationManager.isServiceUsable {
            self.stopTracking()
        } else {
            self.startGPSTrackTimer()
        }
    }
}
