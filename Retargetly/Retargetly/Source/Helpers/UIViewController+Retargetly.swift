//
//  UIViewController+Retargetly.swift
//  Retargetly
//
//  Created by José Valderrama on 8/11/17.
//  Copyright © 2017 NextDots. All rights reserved.
//

import UIKit

extension UIViewController {
    // MARK: - Method Swizzling
    
    @objc func ret_viewDidAppear(animated: Bool) {
        self.ret_viewDidAppear(animated: animated)
        RManager.default.track(et: .change, value: String(describing: self.classForCoder))
    } 
}

