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

    let originalMethod = class_getInstanceMethod(locationManager, originalSelector)
    let swizzledMethod = class_getInstanceMethod(locationManager, swizzledSelector)

    method_exchangeImplementations(originalMethod!, swizzledMethod!)
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
    /// In order to provide UI assistance
    @objc optional func rManager(_ manager: RManager, didSendActionWith message: String)
}

// MARK: - Manager Implementation

/**
 Events Manager, allows to track events.
 
 Manages an singleton property named 'default' for its use
*/
@objcMembers public class RManager: NSObject {
    
    // MARK: - Instance Members
    
    let app: String
    let appn: String
    let sourceHash: String
    let forceGPS: Bool
    let sendGeoData: Bool
    let sendLanguageEnabled: Bool
    let sendManufacturerEnabled: Bool
    let sendDeviceNameEnabled: Bool
    let sendWifiNameEnabled: Bool
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
        guard let deeplinkMessage = RManager.deeplink?.host?.removingPercentEncoding,
            let userIdRange = deeplinkMessage.range(of: "user_id=") else {
            return nil
        }
        
        let relatedID = String(deeplinkMessage[userIdRange.upperBound...])
        return relatedID
    }
    
    public private(set) var rLocationManager: RLocationManager? = nil
    public var delegate: RManagerDelegate? = nil {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                
                if let delegate = strongSelf.delegate {
                    let trackerValues = strongSelf.rLocationManager?.description ?? ""
                    delegate.rManager?(strongSelf, didSendActionWith: "GPS tracker values: \(trackerValues)")
                }
            }
        }
    }
    
    private static var shared: RManager! = nil
    
    /// Singleton instance
    public static var `default`: RManager {
        get {
            if shared == nil {
                fatalError(RError.initializationFatal.errorDescription!)
            }
            
            return shared
        }
    }
    
    public override var description: String {
        return """
        forceGPS: \(forceGPS)
        sendGeoData: \(sendGeoData)
        sendLanguageEnabled: \(sendLanguageEnabled)
        sendManufacturerEnabled: \(sendManufacturerEnabled)
        sendDeviceNameEnabled: \(sendDeviceNameEnabled)
        sendWifiNameEnabled: \(sendWifiNameEnabled)
        """
    }
    
    // MARK: - Methods
    
    private init(with sourceHash: String,
                 sendGeoData: Bool,
                 forceGPS: Bool,
                 sendLanguageEnabled: Bool,
                 sendManufacturerEnabled: Bool,
                 sendDeviceNameEnabled: Bool,
                 sendWifiNameEnabled: Bool) {
        
        guard let app = Bundle.main.bundleIdentifier, let appn = Bundle.main.displayName,
            !sourceHash.isEmpty
            else {
                fatalError(RError.initializationFieldsFatal.errorDescription!)
        }
        
        self.app = app
        self.appn = appn
        self.sourceHash = sourceHash
        self.forceGPS = forceGPS
        self.sendGeoData = sendGeoData
        self.device = UIDevice.current.modelName
        self.language = Locale.current.languageCode
        self.sendLanguageEnabled = sendLanguageEnabled
        self.sendManufacturerEnabled = sendManufacturerEnabled
        self.sendDeviceNameEnabled = sendDeviceNameEnabled
        self.sendWifiNameEnabled = sendWifiNameEnabled
        
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
    
    /// Initialization with full control
    public static func initiate(with sourceHash: String,
                                sendGeoData: Bool = true,
                                forceGPS: Bool = false,
                                sendLanguageEnabled: Bool = true,
                                sendManufacturerEnabled: Bool = true,
                                sendDeviceNameEnabled: Bool = true,
                                sendWifiNameEnabled: Bool = true,
                                callback: CallbackWithError? = nil) {
        
        // Turn off previous implementation
        if shared != nil {
            shared.rLocationManager?.stopTracking()
        }
        
        shared = RManager(with: sourceHash, sendGeoData: sendGeoData, forceGPS: forceGPS, sendLanguageEnabled: sendLanguageEnabled, sendManufacturerEnabled: sendManufacturerEnabled, sendDeviceNameEnabled: sendDeviceNameEnabled, sendWifiNameEnabled: sendWifiNameEnabled)
        shared.initiateSDKWithServer { (json, initWithServerError) in
            shared.track(et: .open, value: nil, callback: { (error) in
                if !(!shared.sendGeoData && !shared.forceGPS) {
                    shared.rLocationManager = RLocationManager(from: json)
                }
                RManager.processDeeplink()
                callback?(error ?? initWithServerError)
            })
        }
    }
    
    // MARK: - Track functionality
    
    static private func processDeeplink() {
        guard let manager = RManager.shared, let deeplink = deeplink else {
            return
        }
        
        manager.delegate?.rManager?(manager, didSendActionWith: "DEEPLINK EVENT - \(deeplink)")
        manager.track(et: .deeplink, value: nil)
    }
    
    /**
     Function that tracks an event, with specific params.
     Uses conection to an endpoint
    */
    public func track(value: JSON?, callback: CallbackWithError? = nil) {
        RManager.default.track(et: .custom, value: value, callback: callback)
    }
    
    internal func track(et: REventType, value: JSON?, callback: CallbackWithError? = nil) {
        if et == .open && value != nil {
            fatalError(RError.openEventWithValue.errorDescription!)
        }
        
        let event = REvent(et: et, value: value)
        RManager.default.track(event: event, callback: callback)
    }
    
    private func initiateSDKWithServer(_ callback: @escaping ApiCallbackWithError) {
        let endpoint = EndpointType.initiate.rawValue
        guard let url = URL(string: endpoint + "/params?source_hash=\(self.sourceHash)") else {
            callback(nil, NSError.errorFromRetargetlyError(.malformedURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(self.sourceHash, forHTTPHeaderField: EndpointParam.sourceHash.rawValue)
        
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                callback(nil, error)
                return
            }
            
            guard let data = data else {
                callback(nil, NSError.errorFromRetargetlyError(.responseDataNotFound))
                return
            }
            
            guard !data.isEmpty else {
                fatalError(RError.possibleInvalidSourceHash.errorDescription!)
            }
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? JSON else {
                    callback(nil, NSError.errorFromRetargetlyError(.responseDataNotSerilizable))
                    return
                }
                
                callback(json, nil)
            } catch {
                callback(nil, error)
            }
            }
            .resume()
    }
    
    private func track(event: REvent, callback: CallbackWithError? = nil) {
        
        let endpoint = EndpointType.track.rawValue
        
        event.getParams { (params) in
            guard let parameters = params else {
                callback?(NSError.errorFromRetargetlyError(.noInformationOnEvent))
                return
            }
            
            guard let url = URL(string: endpoint + "?source_hash=\(RManager.default.sourceHash)") else {
                callback?(NSError.errorFromRetargetlyError(.malformedURL))
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            guard let httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
                fatalError(RError.malformedParams.errorDescription!)
            }
            
            request.httpBody = httpBody
            
            let session = URLSession.shared
            session.dataTask(with: request) { (data, response, error) in
                callback?(error)
                }
                .resume()
        }
    }
}
