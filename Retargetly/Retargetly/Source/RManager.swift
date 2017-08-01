//
//  RManager.swift
//  Retargetly
//
//  Created by José Valderrama on 7/31/17.
//  Copyright © 2017 NextDots. All rights reserved.
//

import Foundation
import Alamofire

// TODO: capitalize
private let initializationFatalErrorMessage = "Please initialize RManager correctly"

fileprivate enum EndpointType: String {
    case track = "api.retargetly.com/ios"
}

public class RManager {
    
    let app: String
    let uid: String
    let pid: String
    let sid: String?
    final let mf: String = "Apple Inc."
    let device: String
    let language: String?
    
    public static var shared: RManager? = nil
    
    private init?(with pid: String, sid: String? = nil) {
        /// verifica si contiene implementado el delegate de PID/SID, sino retorna nil
        guard let app = Bundle.main.bundleIdentifier,
            let uid = UIDevice.current.identifierForVendor?.uuidString,
            !pid.isEmpty
            else { return nil }
        
        self.app = app
        self.uid = uid
        self.pid = pid
        self.sid = sid
        self.device = UIDevice.current.localizedModel
        self.language = Locale.current.languageCode
    }
    
    public static func initiate(with pid: String, sid: String? = nil) -> RManager? {
        shared = RManager(with: pid, sid: sid)
        return shared
    }
    
    static private func validate() -> RManager {
        guard let manager =  RManager.shared else {
            fatalError(initializationFatalErrorMessage)
        }
        
        return manager
    }
    
    // ** TRACK **
    
    public static func track(et: REventType, value: String?) {
        validate().track(with: REvent(et: et, value: value))
    }
    
    /// Function that tracks an event, with specific params.
    /// Uses conection to an endpoint
    private func track(with event: REvent) {
        
    }
}
