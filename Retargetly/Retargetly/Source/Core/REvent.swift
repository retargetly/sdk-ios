//
//  REvent.swift
//  Retargetly
//
//  Created by José Valderrama on 7/31/17.
//  Copyright © 2017 NextDots. All rights reserved.
//

import Foundation

/// Type of event to be tracked
internal enum REventType: String {
    /// User opened app
    case open = "open"
    /// User changed view
    case change = "change"
    /// Custom developer defined events
    case custom = "custom"
}

/// Param name to send in json
internal enum REventParam: String {
    /// Event type
    case et = "et"
    /// String value that makes sense depending on 'et' eventy type
    case value = "value"
    /// Current app bundle identifier
    case app = "app"
    /// device ID
    case uid = "uid"
    /// partner ID
    case pid = "pid"
    /// Optional source ID
    case sid = "sid"
    /// Manufacturer
    case mf = "mf"
    /// Device model
    case device = "device"
    /// Device current language
    case lan = "lan"
}

/// Event itself, contains information to be send as json
internal struct REvent {
    let et: REventType
    let value: String?
    
    var parameters: [String: Any]? {
        let manager = RManager.default
        
        var parameters : [String: Any] =
            [
                REventParam.et.rawValue : et.rawValue,
                REventParam.app.rawValue : manager.app,
                REventParam.uid.rawValue : manager.uid,
                REventParam.pid.rawValue : manager.pid,
                REventParam.mf.rawValue : manager.mf,
                REventParam.device.rawValue : manager.device,
                REventParam.lan.rawValue : manager.language ?? ""
        ]
        
        if let value = self.value {
            parameters.updateValue(value, forKey: REventParam.value.rawValue)
        }
        
        if let sid = manager.sid {
            parameters.updateValue(sid, forKey: REventParam.sid.rawValue)
        }
        
        return parameters
    }
    
    init(et: REventType, value: String?) {
        self.et = et
        self.value = value
    }
}
