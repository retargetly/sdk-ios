//
//  REvent.swift
//  Retargetly
//
//  Created by José Valderrama on 7/31/17.
//  Copyright © 2017 NextDots. All rights reserved.
//

import Foundation
import CoreLocation

/// Type JSON
public typealias JSON = [AnyHashable: Any]

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
    /// IP Address
    case ip = "ip"
    
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
internal class REvent {
    let et: REventType
    let value: JSON?
    
    init(et: REventType, value: JSON?) {
        self.et = et
        self.value = value
    }
    
    func getParams(_ callback: @escaping (_ params: JSON?) -> Void) {
        NetworkUtils.getPublicIP { (publicIP)  in
            let manager = RManager.default
            
            var parameters : JSON =
                [
                    REventParam.et.rawValue : self.et.rawValue,
                    REventParam.uid.rawValue : manager.uid ?? "",
                    REventParam.app.rawValue : manager.app,
                    REventParam.appn.rawValue : manager.appn,
                    REventParam.sourceHash.rawValue : manager.sourceHash,
                    REventParam.lan.rawValue : manager.language ?? "",
                    REventParam.mf.rawValue : manager.mf,
                    REventParam.device.rawValue : manager.device,
                    REventParam.ip.rawValue : publicIP ?? ""
                    ]
            
            if let value = self.value {
                parameters.updateValue(value, forKey: REventParam.value.rawValue)
            }
            
            self.addEventParams(with: &parameters, manager: manager)
            callback(parameters)
        }
    }
    
    private func addEventParams(with parameters: inout JSON, manager: RManager) {
        switch et {
        case .open, .custom:
            guard let relatedID = manager.relatedID else {
                return
            }
            
            RManager.default.delegate?.rManager?(RManager.default, didSendActionWith: "OPEN EVENT - relatedID \(relatedID)")
            parameters.updateValue(relatedID, forKey: REventParam.relatedID.rawValue)
        case .geo:
            guard let locationManager = manager.rLocationManager?.locationManager,
                let location = locationManager.location else {
                    return
            }
            
            let value: JSON = [REventParam.lat.rawValue: location.coordinate.latitude,
                               REventParam.lng.rawValue: location.coordinate.longitude,
                               REventParam.alt.rawValue: location.altitude,
                               REventParam.accuracy.rawValue: location.horizontalAccuracy,
                               REventParam.altAccuracy.rawValue: location.verticalAccuracy,
                               REventParam.nwifi.rawValue: NetworkUtils.getWiFiSSID() ?? ""]
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
