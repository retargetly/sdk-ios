//
//  RAppDelegate.swift
//  Retargetly
//
//  Created by José Valderrama on 24/06/2018.
//  Copyright © 2018 Retargetly. All rights reserved.
//

import UIKit

/// Custom class that allows to receive externals deeplink with the SDK
@objcMembers open class RAppDelegate: UIResponder, UIApplicationDelegate {
    
    open var window: UIWindow?
    
    open func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        RManager.deeplink = url
        return true
    }
}
