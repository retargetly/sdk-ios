//
//  RManagerConfiguration.swift
//  Retargetly
//
//  Created by José Valderrama on 12/01/2021.
//  Copyright © 2021 Retargetly. All rights reserved.
//

/**
 Encapsuled trivial configuration
*/
public struct RManagerConfiguration: CustomDebugStringConvertible {
    public let sourceHash: String
    public let sendGeoData: Bool
    public let forceGPS: Bool
    public let sendLanguageEnabled: Bool
    public let sendManufacturerEnabled: Bool
    public let sendDeviceNameEnabled: Bool
    public let sendWifiNameEnabled: Bool
    
    public var debugDescription: String {
        return """
            sourceHash: \(sourceHash)
            forceGPS: \(forceGPS)
            sendGeoData: \(sendGeoData)
            sendLanguageEnabled: \(sendLanguageEnabled)
            sendManufacturerEnabled: \(sendManufacturerEnabled)
            sendDeviceNameEnabled: \(sendDeviceNameEnabled)
            sendWifiNameEnabled: \(sendWifiNameEnabled)
            """
    }
    
    public init(sourceHash: String,
         sendGeoData: Bool,
         forceGPS: Bool,
         sendLanguageEnabled: Bool,
         sendManufacturerEnabled: Bool,
         sendDeviceNameEnabled: Bool,
         sendWifiNameEnabled: Bool) {
        self.sourceHash = sourceHash
        self.sendGeoData = sendGeoData
        self.forceGPS = forceGPS
        self.sendLanguageEnabled = sendLanguageEnabled
        self.sendManufacturerEnabled = sendManufacturerEnabled
        self.sendDeviceNameEnabled = sendDeviceNameEnabled
        self.sendWifiNameEnabled = sendWifiNameEnabled
    }
    
}
