//
//  Bundle+Retargetly.swift
//  Retargetly
//
//  Created by José Valderrama on 6/7/18.
//  Copyright © 2018 Retargetly. All rights reserved.
//

import Foundation

internal extension Bundle {
    var displayName: String? {
        let name = object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        return name ?? object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String
    }
}
