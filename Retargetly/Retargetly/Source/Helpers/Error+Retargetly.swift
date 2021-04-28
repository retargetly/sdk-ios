//
//  Error+Retargetly.swift
//  Retargetly
//
//  Created by José Valderrama on 6/13/18.
//  Copyright © 2018 Retargetly. All rights reserved.
//

// MARK: - Error Messages

// TODO: make localize files for messages entries in:
// EN: English
// ES: Spanish
// PT: Portuguese
@objc public enum RError: Int, LocalizedError {

    /// Could not initiate becase some fields
    case initializationFieldsFatal
    /// Could not initiate becase IDFA not found
    case idfaNotFound
    /// 'OPEN' event with 'value' is not required
    case openEventWithValue
    /// There is not params to send
    case noInformationOnEvent
    /// URL is malformed
    case malformedURL
    /// There is not data response
    case responseDataNotFound
    /// Location service not allowed or denied
    case locationServiceNotAllowedOrDenied
    
    public var errorDescription: String? {
        switch self {
        case .initializationFieldsFatal: return NSLocalizedString("Please initialize RManager correctly, source hash is mandatory. If you don't have one, please contact your Retargetly's account manager to get it.", comment: "")
        case .idfaNotFound: return NSLocalizedString("Please initialize RManager correctly, IDFA (advertising tracking) is mandatory. Must accept the permissions on devices setting.", comment: "")
        case .openEventWithValue: return NSLocalizedString("Please don't provide a 'value' for <open> event.", comment: "")
        case .noInformationOnEvent: return NSLocalizedString("Event without params to send.", comment: "")
        case .malformedURL: return NSLocalizedString("The URL is malformed, please check it.", comment: "")
        case .responseDataNotFound: return NSLocalizedString("An error has occurred while connecting to Retargetly's servers. You've probably setup a wrong source hash, please contact your Retargetly's account manager to validate it.", comment: "")
        case .locationServiceNotAllowedOrDenied: return NSLocalizedString("The Location Service is not allowed or is denied to this app, please review it on app's Settings.", comment: "")
        }
    }
    
}
