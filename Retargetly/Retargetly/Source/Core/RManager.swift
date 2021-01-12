//
//  RManager.swift
//  Retargetly
//
//  Created by José Valderrama on 7/31/17.
//  Copyright © 2017 Retargetly. All rights reserved.
//

import Foundation
import CoreLocation
import AdSupport
import UIKit

// MARK: - Swizzling implementation for CLLocationManager classes

private let swizzlingCLLocationManager: (CLLocationManager.Type) -> () = { locationManager in
    
    // startUpdatingLocation
    let originalSelector = #selector(locationManager.startUpdatingLocation)
    let swizzledSelector = #selector(locationManager.ret_startUpdatingLocation)
    
    guard let originalMethod = class_getInstanceMethod(locationManager, originalSelector),
          let swizzledMethod = class_getInstanceMethod(locationManager, swizzledSelector)
    else { return }
    
    method_exchangeImplementations(originalMethod, swizzledMethod)
}

// MARK: - Internal Helpers

public typealias CallbackWithError = (_ error: Error?) -> Void
public typealias ApiCallbackWithError = (_ json: JSON?, _ error: Error?) -> Void

fileprivate enum EndpointType: String {
    case initiate = "https://api.retargetly.com/sdk"
    case track = "https://api.retargetly.com/ios"
}

fileprivate enum EndpointParam: String {
    case sourceHash = "source_hash"
}

@objc public protocol RManagerDelegate: class {
    /// In order to provide UI assistance, you should ensure to display on main thread
    @objc optional func rManager(_ manager: RManager, didSendActionWith message: String)
}

// MARK: - Manager Implementation

/**
 Events Manager, allows to track events.
 
 Manages a singleton property named 'default' for its use
*/
@objcMembers public class RManager: NSObject {
    
    // MARK: - Instance Members
    
    let app: String
    let appn: String
    
    let config: RManagerConfiguration
    
    final let mf: String = "Apple Inc."
    let device: String
    let language: String?
    // Check whether advertising tracking is enabled then get and return IDFA
    var uid: String? {
        return !ASIdentifierManager.shared().isAdvertisingTrackingEnabled ? nil :
        ASIdentifierManager.shared().advertisingIdentifier.uuidString
    }
    static var deeplink: URL? = nil {
        didSet {
            processDeeplink()
        }
    }
    var relatedID : String? {
        guard let deeplinkMessage = Self.deeplink?.host?.removingPercentEncoding,
            let userIdRange = deeplinkMessage.range(of: "user_id=") else {
            return nil
        }
        
        let relatedID = String(deeplinkMessage[userIdRange.upperBound...])
        return relatedID
    }
    
    public private(set) var rLocationManager: RLocationManager? = nil
    public var delegate: RManagerDelegate? = nil {
        didSet {
            if let delegate = delegate {
                let trackerValues = rLocationManager?.description ?? ""
                delegate.rManager?(self,
                                   didSendActionWith: "GPS tracker values: \(trackerValues)")
            }
        }
    }
    
    /// Singleton instance
    public private(set) static var `default`: RManager?
    
    // MARK: - Methods
    
    private init(config: RManagerConfiguration)  throws {
        guard let app = Bundle.main.bundleIdentifier,
              let appn = Bundle.main.displayName,
              !config.sourceHash.isEmpty
        else {
            throw RError.initializationFieldsFatal
        }
        
        self.app = app
        self.appn = appn
        self.device = UIDevice.current.modelName
        self.language = Locale.current.languageCode
        self.config = config
        
        super.init()
        swizzlingCLLocationManager(CLLocationManager.self)
    }
    
    /// Initialization with preset configuration
    public static func initiate(activeOptionalFlags: Bool = true,
                                sourceHash: String,
                                callback: CallbackWithError? = nil) {
        
        if activeOptionalFlags {
            initiate(with: sourceHash, callback: callback)
        } else {
            initiate(with: sourceHash, sendGeoData: false, forceGPS: false, sendLanguageEnabled: false, sendManufacturerEnabled: false, sendDeviceNameEnabled: false, sendWifiNameEnabled: false, callback: callback)
        }
    }
    
    /// Obj-C brigde builder
    public static func initiate(with sourceHash: String,
                                sendGeoData: Bool = true,
                                forceGPS: Bool = false,
                                sendLanguageEnabled: Bool = true,
                                sendManufacturerEnabled: Bool = true,
                                sendDeviceNameEnabled: Bool = true,
                                sendWifiNameEnabled: Bool = true,
                                callback: CallbackWithError? = nil) {
        let config = RManagerConfiguration(sourceHash: sourceHash,
                                           sendGeoData: sendGeoData,
                                           forceGPS: forceGPS,
                                           sendLanguageEnabled: sendLanguageEnabled,
                                           sendManufacturerEnabled: sendManufacturerEnabled,
                                           sendDeviceNameEnabled: sendDeviceNameEnabled,
                                           sendWifiNameEnabled: sendWifiNameEnabled)
        initiate(with: config, callback: callback)
    }
    
    /// Initialization with full control
    /// We manage errors via callback since the initialization requires an async call
    public static func initiate(with config: RManagerConfiguration, callback: CallbackWithError? = nil) {
        do {
            let manager = try RManager(config: config)
            
            manager.initiateSDKWithServer { (json, initWithServerError) in
                guard initWithServerError == nil else {
                    callback?(initWithServerError)
                    return
                }
                
                // Override
                Self.default?.rLocationManager?.stopTracking()
                Self.default = manager
                
                if !(!manager.config.sendGeoData && !manager.config.forceGPS) {
                    manager.rLocationManager = RLocationManager(from: json)
                }
                
                manager.track(et: .open, value: nil, callback: { (error) in
                    guard error == nil else {
                        callback?(error)
                        return
                    }
                    
                    Self.processDeeplink(callback)
                })
            }
        } catch  {
            callback?(error)
        }
    }
    
    // MARK: - Track functionality
    
    static private func processDeeplink(_ callback: CallbackWithError? = nil) {
        guard let manager = Self.default, let deeplink = deeplink else {
            callback?(nil)
            return
        }
        
        manager.delegate?.rManager?(manager, didSendActionWith: "DEEPLINK EVENT - \(deeplink)")
        manager.track(et: .deeplink, value: nil, callback: callback)
    }
    
    /**
     Function that tracks an event, with specific params.
     Uses conection to an endpoint
    */
    public func track(value: JSON?, callback: CallbackWithError? = nil) {
        track(et: .custom, value: value, callback: callback)
    }
    
    internal func track(et: REventType, value: JSON?, callback: CallbackWithError? = nil) {
        // 'open' and value not allowed
        if et == .open && value != nil {
            callback?(RError.openEventWithValue)
            return
        }
        
        let event = REvent(et: et, value: value)
        track(event: event, callback: callback)
    }
    
    private func initiateSDKWithServer(_ callback: @escaping ApiCallbackWithError) {
        let endpoint = EndpointType.initiate.rawValue
        guard let url = URL(string: endpoint + "/params?source_hash=\(self.config.sourceHash)") else {
            callback(nil, RError.malformedURL)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(self.config.sourceHash, forHTTPHeaderField: EndpointParam.sourceHash.rawValue)
        
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) in
            guard error == nil,
                  let data = data,
                  !data.isEmpty,
                  let json = try? JSONSerialization.jsonObject(with: data, options: []) as? JSON else {
                callback(nil, error ?? RError.responseDataNotFound)
                return
            }
            
            callback(json, nil)
        }
        .resume()
    }
    
    private func track(event: REvent, callback: CallbackWithError? = nil) {
        let endpoint = EndpointType.track.rawValue
        
        guard let parameters = event.params,
              let url = URL(string: endpoint + "?source_hash=\(self.config.sourceHash)"),
              let httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
            callback?(RError.noInformationOnEvent)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody
        
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) in
            callback?(error)
        }
        .resume()
    }
    
}
