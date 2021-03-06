//
//  REvent.swift
//  Retargetly
//
//  Created by José Valderrama on 7/31/17.
//  Copyright © 2017 Retargetly. All rights reserved.
//

import CoreLocation

/// Type JSON
public typealias JSON = [AnyHashable: Any]

// TODO: make this with associated value
/// Type of event to be tracked
internal enum REventType: String {
    /// User opened app
    case open = "open"
    /// Custom developer defined events
    case custom = "custom"
    /// Device geo-position
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
    /// Current app display name
    case appn = "appn"
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
    
    // MARK: - GEO Event Params
    /// Device location latitude
    case lat = "lat"
    /// Device location longitude
    case lng = "lng"
    /// Device location altitude
    case alt = "alt"
    /// Device location horizontal accuracy
    case accuracy = "accuracy"
    /// Device location vertical accuracy
    case altAccuracy = "altaccuracy"
    /// SSID WiFi Address
    case nwifi = "nwifi"
    
    // MARK: - DEEPLINK Event Params
    /// External URL received
    case link = "link"
    /// RelatedID from external URL received
    case relatedID = "related_id"
}

/// Event itself, contains information to be send as JSON
internal struct REvent {
    let et: REventType
    let value: JSON?
    
    var params: JSON? {
        guard let manager = RManager.default else {
            return nil
        }
        
        var parameters: JSON =
            [
                REventParam.et.rawValue : self.et.rawValue,
                REventParam.uid.rawValue : manager.uid,
                REventParam.app.rawValue : manager.app,
                REventParam.appn.rawValue : manager.appn,
                REventParam.sourceHash.rawValue : manager.config.sourceHash
            ]
        
        if let value = self.value {
            parameters.updateValue(value, forKey: REventParam.value.rawValue)
        }
        
        if manager.config.sendLanguageEnabled {
            parameters.updateValue(manager.language ?? "", forKey: REventParam.lan.rawValue)
        }
        
        if manager.config.sendManufacturerEnabled {
            parameters.updateValue(manager.mf, forKey: REventParam.mf.rawValue)
        }
        
        if manager.config.sendDeviceNameEnabled {
            parameters.updateValue(manager.device, forKey: REventParam.device.rawValue)
        }
        
        self.addEventParams(with: &parameters, manager: manager)
        return parameters
    }
    
    init(et: REventType, value: JSON?) {
        self.et = et
        self.value = value
    }
    
    private func addEventParams(with parameters: inout JSON, manager: RManager) {
        switch et {
        case .open, .custom:
            guard let relatedID = manager.relatedID else {
                return
            }
            
            manager.delegate?.rManager?(manager, didSendActionWith: "\(et.rawValue.uppercased()) EVENT - relatedID \(relatedID)")
            parameters.updateValue(relatedID, forKey: REventParam.relatedID.rawValue)
            
        case .geo:
            guard let locationManager = manager.rLocationManager?.locationManager,
                  let location = locationManager.location else {
                return
            }
            
            var value: JSON = [REventParam.lat.rawValue: location.coordinate.latitude,
                               REventParam.lng.rawValue: location.coordinate.longitude,
                               REventParam.alt.rawValue: location.altitude,
                               REventParam.accuracy.rawValue: location.horizontalAccuracy,
                               REventParam.altAccuracy.rawValue: location.verticalAccuracy]
            
            if manager.config.sendWifiNameEnabled {
                value.updateValue(UIDevice.current.WiFiSSID ?? "", forKey: REventParam.nwifi.rawValue)
            }
            
            parameters.updateValue(value, forKey: REventParam.value.rawValue)
            
        case .deeplink:
            guard let deeplink = RManager.deeplink else {
                return
            }
            
            let value: JSON = [REventParam.link.rawValue: deeplink.absoluteString]
            parameters.updateValue(value, forKey: REventParam.value.rawValue)
            break
        }
    }
    
}
