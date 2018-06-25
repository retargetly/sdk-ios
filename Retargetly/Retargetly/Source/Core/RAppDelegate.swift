//
//  RAppDelegate.swift
//  Retargetly
//
//  Created by José Valderrama on 24/06/2018.
//  Copyright © 2018 NextDots. All rights reserved.
//

import UIKit

open class RAppDelegate: UIResponder, UIApplicationDelegate {
    
    open var window: UIWindow?
    
    open func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        RManager.deeplink = url
        return true
    }
}
