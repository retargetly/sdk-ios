//
//  RManager.swift
//  Retargetly
//
//  Created by José Valderrama on 7/31/17.
//  Copyright © 2017 NextDots. All rights reserved.
//

import Foundation
import CoreLocation

// MARK: - Swizzling implementation for UIViewController classes

private let swizzlingUIViewController: (UIViewController.Type) -> () = { viewController in
    
    let originalSelector = #selector(viewController.viewDidAppear(_:))
    let swizzledSelector = #selector(viewController.ret_viewDidAppear(animated:))
    
    let originalMethod = class_getInstanceMethod(viewController, originalSelector)
    let swizzledMethod = class_getInstanceMethod(viewController, swizzledSelector)
    
    method_exchangeImplementations(originalMethod, swizzledMethod)
    
}

// MARK: - Swizzling implementation for CLLocationManager classes

private let swizzlingCLLocationManager: (CLLocationManager.Type) -> () = { locationManager in

    let originalSelector = #selector(locationManager.startUpdatingLocation)
    let swizzledSelector = #selector(locationManager.ret_startUpdatingLocation)

    let originalMethod = class_getInstanceMethod(locationManager, originalSelector)
    let swizzledMethod = class_getInstanceMethod(locationManager, swizzledSelector)

    method_exchangeImplementations(originalMethod, swizzledMethod)
}

// MARK: - Error Messages

private let initializationFatalErrorMessage = "Please initialize RManager correctly"
private let initializationFieldsFatalErrorMessage = "Please initialize RManager correctly, some fields are empty or not allowed"
private let openEventWithValueErrorMessage = "Please don't provide a 'value' for <open> event"
private let eventWithoutValueErrorMessage = "Please provide a 'value' for the event"
private let noInformationOnEventErrorMessage = "Event without params to send"
private let malformedParamsErrorMessage = "Some information is malformed on params"
private let malformedURLErrorMessage = "The URL is malformed, please check it"

// MARK: - Internal Helpers

public typealias callbackWithError = (_ error: Error?) -> Void

fileprivate enum EndpointType: String {
    case track = "https://api.retargetly.com/ios"
}

fileprivate enum EndpointParam: String {
    case ios_hash = "ios_hash"
}

// MARK: - Manager Implementation

/**
 Events Manager, allows to track events.
 
 Manages an singleton property named 'default' for its use
*/
public class RManager {
    
    // MARK: - Instance Members
    
    let app: String
    let uid: String
    let pid: String
    let sid: String?
    final let mf: String = "Apple Inc."
    let device: String
    let language: String?
    let iosHash: String
    
    open var locationManager: CLLocationManager? = nil
    
    private static var shared: RManager! = nil
    
    /// Singleton instance
    public static var `default`: RManager {
        get {
            if shared == nil {
                fatalError(initializationFatalErrorMessage)
            }
            
            return shared
        }
    }
    
    // MARK: - Methods
    
    private init(with iosHash: String, pid: String, sid: String? = nil) {
        guard let app = Bundle.main.bundleIdentifier,
            let uid = UIDevice.current.identifierForVendor?.uuidString,
            !pid.isEmpty,
            !iosHash.isEmpty
            else {
                fatalError(initializationFieldsFatalErrorMessage)
        }
        
        self.iosHash = iosHash
        self.app = app
        self.uid = uid
        self.pid = pid
        self.sid = sid
        self.device = UIDevice.current.modelName
        self.language = Locale.current.languageCode
        
        swizzlingUIViewController(UIViewController.self)
        swizzlingCLLocationManager(CLLocationManager.self)
        
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActiveAction(notification:)), name: .UIApplicationDidBecomeActive, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    public static func initiate(with iosHash: String, pid: String, sid: String? = nil, forceGPS: Bool = false) {
        shared = RManager(with: iosHash, pid: pid, sid: sid)
        shared.track(et: .open, value: nil)
        forceGPS ? shared.useLocation() : ()
    }
    
    @objc private func appDidBecomeActiveAction(notification: NSNotification) {
        RManager.default.track(et: .active, value: nil)
    }
    
    private func useLocation() {
        locationManager = CLLocationManager()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager?.requestWhenInUseAuthorization()
        }
    }
    
    // MARK: TRACK
    
    /**
     Function that tracks an event, with specific params.
     Uses conection to an endpoint
    */
    public func track(value: JSON?, callback: callbackWithError? = nil) {
        RManager.default.track(et: .custom, value: value, callback: callback)
    }
    
    internal func track(et: REventType, value: JSON?, callback: callbackWithError? = nil) {
        if et == .open && value != nil {
            fatalError(openEventWithValueErrorMessage)
        }
        
        let event = REvent(et: et, value: value)
        RManager.default.track(event: event, callback: callback)
    }
    
    private func track(event: REvent, callback: callbackWithError? = nil) {
        
        let endpoint = EndpointType.track.rawValue
        
        guard let parameters = event.parameters else {
            fatalError(noInformationOnEventErrorMessage)
        }
        
        guard let url = URL(string: endpoint) else {
            fatalError(malformedURLErrorMessage)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(self.iosHash, forHTTPHeaderField: EndpointParam.ios_hash.rawValue)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
            fatalError(malformedParamsErrorMessage)
        }
        
        request.httpBody = httpBody
        
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) in
            callback?(error)
            }.resume()
    }
}
