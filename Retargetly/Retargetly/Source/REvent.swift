//
//  REvent.swift
//  Retargetly
//
//  Created by José Valderrama on 7/31/17.
//  Copyright © 2017 NextDots. All rights reserved.
//

import Foundation

typealias JSON = [REventParam : Any]

enum REventType: String {
    /// User opened app
    case open = "open"
    /// User changed view
    case change = "change"
    /// Custom developer defined events
    case custom = "custom"
}

enum REventParam: String {
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

struct REvent {
    let et: REventType
    let value: String?
    
    init(et: REventType, value: String?) {
        self.et = et
        self.value = value
    }
    
    func toJSON() -> JSON? {
        /// checks if manager has already initialized, else return nil
        guard let manager = RManager.shared else { return nil }
        
        var json : JSON =
            [
                .et : et,
                .app : manager.app,
                .uid : manager.uid,
                .pid : manager.pid,
                .mf : manager.mf,
                .device : manager.device,
                .lan : manager.language ?? ""
            ]
        
        if let value = self.value {
            json.updateValue(value, forKey: .value)
        }
        
        if let sid = manager.sid {
            json.updateValue(sid, forKey: .sid)
        }
        
        return json
    }
}
