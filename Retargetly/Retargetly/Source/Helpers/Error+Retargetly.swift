//
//  Error+Retargetly.swift
//  Retargetly
//
//  Created by José Valderrama on 6/13/18.
//  Copyright © 2018 Retargetly. All rights reserved.
//

import Foundation

// MARK: - Error Messages

// TODO: make localize files for messages entries in:
// EN: English
// ES: Spanish
// PT: Portuguese
@objc public enum RError: Int, CustomNSError, LocalizedError {
    
    /// Could not initiate the SDK
    case initializationFatal
    /// Could not initiate becase some fields
    case initializationFieldsFatal
    /// 'OPEN' event with 'value' is not required
    case openEventWithValue
    /// Event without 'value' when required
    case eventWithoutValue
    /// There is not params to send
    case noInformationOnEvent
    /// Some information is malformed on params
    case malformedParams
    /// URL is malformed
    case malformedURL
    /// There is not data response
    case responseDataNotFound
    /// Possible invalid source hash
    case possibleInvalidSourceHash
    /// Response data not serializable
    case responseDataNotSerilizable
    /// Location service not allowed or denied
    case locationServiceNotAllowedOrDenied
    
    public var errorDescription: String? {
        switch self {
        case .initializationFatal: return NSLocalizedString("Please initiate RManager correctly.", comment: "")
        case .initializationFieldsFatal: return NSLocalizedString("Please initialize RManager correctly, some fields are empty or not allowed.", comment: "")
        case .openEventWithValue: return NSLocalizedString("Please don't provide a 'value' for <open> event.", comment: "")
        case .eventWithoutValue: return NSLocalizedString("Please provide a 'value' for the event.", comment: "")
        case .noInformationOnEvent: return NSLocalizedString("Event without params to send.", comment: "")
        case .malformedParams: return NSLocalizedString("Some information is malformed on params.", comment: "")
        case .malformedURL: return NSLocalizedString("The URL is malformed, please check it.", comment: "")
        case .responseDataNotFound: return NSLocalizedString("There is no data response, please try again.", comment: "")
        case .possibleInvalidSourceHash: return NSLocalizedString("Possible invalid source hash, please review it and try again.", comment: "")            
        case .responseDataNotSerilizable: return NSLocalizedString("Could not serialize data response, please try again.", comment: "")
        case .locationServiceNotAllowedOrDenied: return NSLocalizedString("The Location Service is not allowed or is denied to this app, please review it on app's Settings.", comment: "")
        }
    }
    
    public var errorCode: Int {
        return self.rawValue
    }
    
    public static var errorDomain : String {
        return "Retargetly"
    }
    
}

//public enum RErrorFromServer: String, CustomStringConvertible {
//
//
//    public var description: String {
//        switch self {
//        }
//    }
//}

public extension NSError {
    
    @objc class func errorFromString(_ reason: String) -> NSError? {
        return NSError(domain: RError.errorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey : reason])
    }
    
//    @objc class public func errorFromServer(_ error: RErrorFromServer) -> NSError? {
//        return NSError(domain: RError.errorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey : error.description])
//    }
    
    @objc class func errorFromRetargetlyError(_ retargetlyError: RError) -> NSError? {
        return NSError(domain: RError.errorDomain, code: retargetlyError.errorCode, userInfo: [NSLocalizedDescriptionKey : retargetlyError.errorDescription ?? retargetlyError.localizedDescription])
    }
    
}
