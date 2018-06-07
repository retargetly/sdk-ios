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
    /// Custom developer defined events
    case custom = "custom"
    /// Geo-position
    case geo = "geo"
    /// When the app was open from a external link (banner ad)
    case deeplink = "deeplink"
}

/// Param name to send in json
internal enum REventParam: String {
    // MARK: - Common Event Params
    /// Event type
    case et = "et"
    /// UID of Google
    case uid = "uid"
    /// Current app bundle identifier
    case app = "app"
    /// Source Hash
    case sourceHash = "source_hash"
    /// String value that makes sense depending on 'et' event type. Mostly `custom` REventType
    case value = "value"
    /// Device current language
    case lan = "lan"
    /// Manufacturer
    case mf = "mf"
    /// Device model
    case device = "device"
    /// IP Address
    case ip = "ip"
    /// SSID WiFi Address
    case nwifi = "nwifi"
    
    // MARK: - GEO Event Params
    /// Device current position
    case rPosition = "rPosition"
    
    // MARK: - DEEPLINK Event Params
    /// External URL received
    case link = "link"
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
                REventParam.uid.rawValue : manager.uid ?? "",
                REventParam.app.rawValue : manager.app,
                REventParam.sourceHash.rawValue : manager.sourceHash,
                REventParam.lan.rawValue : manager.language ?? "",
                REventParam.mf.rawValue : manager.mf,
                REventParam.device.rawValue : manager.device,
                // TODO: implement this propertly
                REventParam.ip.rawValue : "127.0.0.1",
                REventParam.nwifi.rawValue : "A nice wifi",
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
