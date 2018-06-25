//
//  NetworkUtils.swift
//  Retargetly
//
//  Created by José Valderrama on 6/6/18.
//  Copyright © 2018 NextDots. All rights reserved.
//

import Foundation
import SystemConfiguration.CaptiveNetwork

/// Tuple for network address
/// String: IP Address
/// Bool: if Wifi address or not
public typealias NetAddress = (String, Bool)

public class NetworkUtils {
    
    private init(){}
    
    // Returns the WiFi's name if connected
    public class func getWiFiSSID() -> String? {
        var ssid: String?
        if let interfaces = CNCopySupportedInterfaces() as NSArray? {
            for interface in interfaces {
                if let interfaceInfo = CNCopyCurrentNetworkInfo(interface as! CFString) as NSDictionary? {
                    ssid = interfaceInfo[kCNNetworkInfoKeySSID as String] as? String
                    break
                }
            }
        }
        return ssid
    }
    
    /// Returns public IP by a web page service
    public class func getPublicIP(_ callback: @escaping (_ publicIP: String?) -> Void) {
        // Portal that brings us public IP as response
        let urlString = "https://icanhazip.com/"
        guard let url = URL(string: urlString) else {
            callback(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) in
            guard let data = data, error == nil else {
                callback(nil)
                return
            }
            
            let publicIP = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .newlines)
            callback(publicIP)
            }.resume()
    }
}
