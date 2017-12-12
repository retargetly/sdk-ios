//
//  REvent.swift
//  Retargetly
//
//  Created by José Valderrama on 7/31/17.
//  Copyright © 2017 NextDots. All rights reserved.
//

import Foundation

/// Type JSON
public typealias JSON = [String: Any]

/// Type of event to be tracked
internal enum REventType: String {
    /// User opened app
    case open = "open"
    /// User changed view
    case change = "change"
    /// Custom developer defined events
    case custom = "custom"
    /// App become active
    case active = "active"
}

/// Param name to send in json
internal enum REventParam: String {
    /// Event type
    case et = "et"
    /// String value that makes sense depending on 'et' event type
    case value = "value"
    /// Current app bundle identifier
    case app = "app"
    /// sourceHash
    case sourceHash = "source_hash"
    /// Manufacturer
    case mf = "mf"
    /// Device model
    case device = "device"
    /// Device current language
    case lan = "lan"
    /// Device current position
    case rPosition = "rPosition"
    /// Name of new UIViewController presented
    case named = "named"
    /// Uid of Google
    case uid = "uid"
}

/// Event itself, contains information to be send as JSON
internal struct REvent {
    let et: REventType
    let value: JSON?
    
    var parameters: JSON? {
        let manager = RManager.default
        
        var parameters : JSON =
            [
                REventParam.et.rawValue : et.rawValue,
                REventParam.app.rawValue : manager.app,
                REventParam.sourceHash.rawValue : manager.sourceHash,
                REventParam.mf.rawValue : manager.mf,
                REventParam.device.rawValue : manager.device,
                REventParam.lan.rawValue : manager.language ?? "",
                REventParam.uid.rawValue : manager.uid
        ]
        
        if let value = self.value {
            parameters.updateValue(value, forKey: REventParam.value.rawValue)
        }
        
        return parameters
    }
    
    init(et: REventType, value: JSON?) {
        self.et = et
        self.value = value
    }
}
