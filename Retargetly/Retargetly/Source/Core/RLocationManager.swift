//
//  RLocationManager.swift
//  Retargetly
//
//  Created by José Valderrama on 17/06/2018.
//  Copyright © 2018 Retargetly. All rights reserved.
//

import CoreLocation

@objc public protocol RLocationManagerDelegate: AnyObject {
    /// Mirror for same method didUpdateLocations: on CLLocationManager
    @objc optional func rLocationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    /// Mirror for same method didFailWithError: on CLLocationManager
    @objc optional func rlocationManager(_ manager: CLLocationManager, didFailWith error: Error)
}

/**
 Retargetly Location Service manager, allows to track GPS values.
 */
@objcMembers public class RLocationManager: NSObject {
    
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
            
            if let manager = RManager.default {
                manager.delegate?.rManager?(manager, didSendActionWith: "motionState \(motionState)")
            }
        }
    }
    
    // MARK: - CoreLocation
    /// CoreLocation location manager
    public private(set) var locationManager: CLLocationManager?
    
    /// Retargetly location delegate
    public weak var delegate: RLocationManagerDelegate?
    /// Last location received
    fileprivate var lastLocation: CLLocation?
    
    // Timers
    fileprivate var gpsTrackTimer: DispatchSourceTimer?
    fileprivate var stateTrackTimer: DispatchSourceTimer?
    
    private final let noneStateTrackTimerInterval: TimeInterval = -1
    private var stateTrackTimerInterval: TimeInterval {
        switch motionState {
        case .inMotion:
            return motionFrequency
        case .noEnoughtMotion:
            return staticFrequency
        default:
            return noneStateTrackTimerInterval
        }
    }
    
    override public var description: String {
        return "motionFrequency: \(motionFrequency) - staticFrequency: \(staticFrequency) -  motionDetectionFrequency: \(motionDetectionFrequency) -  motionThreshold: \(motionThreshold) "
    }
    
    // MARK: - Initialization
    
    deinit {
        stopTracking()
    }
    
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
                 motionThreshold: CLLocationDistance = kMotionThreshold) {
        
        self.motionFrequency = motionFrequency
        self.staticFrequency = staticFrequency
        self.motionDetectionFrequency = motionDetectionFrequency
        self.motionThreshold = motionThreshold
        super.init()
        DispatchQueue.main.async { [weak self] in
            self?.configureCLLocationManager()
        }
    }
    
    /// Configures the CLLocationManager inside RLocationManager
    /// This method checks if UIBackgroundModes:location is enable in info.plist file
     func configureCLLocationManager() {
        defer {
            askLocationServiceIfNeeded()
        }
        
        locationManager = CLLocationManager()
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.distanceFilter = kCLDistanceFilterNone
        locationManager?.pausesLocationUpdatesAutomatically = false
        lastLocation = locationManager?.location
        
        // Only if has background mode for location service
        guard let info = Bundle.main.infoDictionary,
              let backgroundModes = info["UIBackgroundModes"] as? [String : Any],
              let _ = backgroundModes["location"] else {
            return
        }
        
        locationManager?.allowsBackgroundLocationUpdates = true
    }
    
    /// Ask for location services authorization only if needed
    private func askLocationServiceIfNeeded() {
        // If forceGPS is required and location services are enabled
        guard RManager.default?.config.forceGPS == true,
              CLLocationManager.locationServicesEnabled()
        else {
            if let delegate = delegate,
               let locationManager = locationManager {
                delegate.rlocationManager?(locationManager,
                                            didFailWith: RError.locationServiceNotAllowedOrDenied)
            }
            return
        }
        
        locationManager?.delegate = self
        locationManager?.requestAlwaysAuthorization()
    }
    
    // MARK: - Track GPS
    
    func releaseTimer(_ timer: inout DispatchSourceTimer?) {
        timer?.cancel()
        timer?.setEventHandler(handler: nil)
        timer = nil
    }
    
    func createTimer(interval: TimeInterval,
                     handler: DispatchSourceProtocol.DispatchSourceHandler?) -> DispatchSourceTimer {
        let timer = DispatchSource.makeTimerSource()
        timer.schedule(deadline: .now() + interval, repeating: interval)
        timer.setEventHandler(handler: handler)
        
        if #available(iOS 10.0, *) {
            timer.activate()
        } else {
            timer.resume()
        }
        
        return timer
    }
    
    func startGPSTrackTimer() {
        // Operates only if track timer is nil
        guard self.gpsTrackTimer == nil,
              RManager.default?.config.sendGeoData == true,
              let locationManager = locationManager else {
            return
        }
        
        releaseTimer(&gpsTrackTimer)
        
        // Creates and schedule the new track timer
        sendTrackedLocation()
        gpsTrackTimer = createTimer(interval: motionDetectionFrequency,
                    handler: locationManager.startUpdatingLocation)
    }
    
    func startStateTrackTimer() {
        guard RManager.default?.config.sendGeoData == true,
              stateTrackTimerInterval != noneStateTrackTimerInterval else {
            return
        }
        
        releaseTimer(&stateTrackTimer)
        
        // Creates and schedule the new track timer
        stateTrackTimer = createTimer(interval: stateTrackTimerInterval,
                                      handler: sendTrackedLocation)
    }
    
    func stopTracking(removeDelegate: Bool = true) {
        if removeDelegate {
            locationManager?.delegate = nil
        }
        locationManager?.stopUpdatingLocation()
        releaseTimer(&gpsTrackTimer)
        releaseTimer(&stateTrackTimer)
        motionState = .unknown
    }
    
    // MARK: - Location Functionality
    
    fileprivate func doLocationFunctionality(with newLocation: CLLocation) {
        defer {
            self.lastLocation = newLocation
        }
        
        guard let lastLocation = self.lastLocation,
              let manager = RManager.default else {
            return
        }
        
        let distance = lastLocation.distance(from: newLocation)
        manager.delegate?.rManager?(manager, didSendActionWith: "Covered meters: \(distance)")
        
        motionState = distance >= self.motionThreshold ?
            .inMotion :
            .noEnoughtMotion
    }
    
    @objc private func sendTrackedLocation() {
        guard let manager = RManager.default else {
            return
        }
        
        manager.track(et: .geo, value: nil)
        manager.delegate?.rManager?(manager, didSendActionWith: "GEO EVENT - Sent type \(self.motionState)")
    }
    
}

// MARK: - CLLocationManagerDelegate

extension RLocationManager: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.locationManager?.stopUpdatingLocation()
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
            self.stopTracking(removeDelegate: false)
        } else {
            self.startGPSTrackTimer()
        }
    }
}
