//
//  RManager.swift
//  Retargetly
//
//  Created by José Valderrama on 7/31/17.
//  Copyright © 2017 NextDots. All rights reserved.
//

import Foundation

// MARK: Error Messages

private let initializationFatalErrorMessage = "Please initialize RManager correctly"
private let openEventWithValueErrorMessage = "Please don't provide a 'value' for <open> event"
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

/**
 Events Manager, allows to track events.
 
 Manages an singleton property named 'shared' for its use
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
    
    /// Singleton instance
    internal static var shared: RManager? = nil
    
    // MARK: - Methods
    
    private init?(with iosHash: String, pid: String, sid: String? = nil) {
        guard let app = Bundle.main.bundleIdentifier,
            let uid = UIDevice.current.identifierForVendor?.uuidString,
            !pid.isEmpty,
            !iosHash.isEmpty
            else { return nil }
        
        self.iosHash = iosHash
        self.app = app
        self.uid = uid
        self.pid = pid
        self.sid = sid
        self.device = UIDevice.current.modelName
        self.language = Locale.current.languageCode
    }
    
    public static func initiate(with iosHash: String, pid: String, sid: String? = nil) -> RManager? {
        shared = RManager(with: iosHash, pid: pid, sid: sid)
        RManager.track(et: .open, value: nil)
        return shared
    }
    
    static private func validate() -> RManager {
        guard let manager =  RManager.shared else {
            fatalError(initializationFatalErrorMessage)
        }
        
        return manager
    }
    
    // MARK: TRACK
    
    /**
     Function that tracks an event, with specific params.
     Uses conection to an endpoint
    */
    public static func track(value: String?, callback: callbackWithError? = nil) {
        RManager.track(et: .custom, value: value, callback: callback)
    }
    
    internal static func track(et: REventType, value: String?, callback: callbackWithError? = nil) {
        guard (et == .open && value == nil) || (et != .open && value != nil) else {
            fatalError(openEventWithValueErrorMessage)
        }
        
        let manager = validate()
        let event = REvent(et: et, value: value)
        manager.track(with: manager, event: event, callback: callback)
    }
    
    private func track(with manager: RManager, event: REvent, callback: callbackWithError? = nil) {
        
        let endpoint = EndpointType.track.rawValue
        
        guard let parameters: [String: Any] = event.parameters else {
            fatalError(noInformationOnEventErrorMessage)
        }
        
        print(event.et, parameters, "\n")
        
        guard let url = URL(string: endpoint) else {
            fatalError(malformedURLErrorMessage)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(manager.iosHash, forHTTPHeaderField: EndpointParam.ios_hash.rawValue)
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
