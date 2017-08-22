//
//  RViewController.swift
//  Retargetly
//
//  Created by José Valderrama on 8/11/17.
//  Copyright © 2017 NextDots. All rights reserved.
//

import UIKit

/// Use this class in inheritance or extension to allow tracking of the screen change event
open class RViewController: UIViewController {

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        RManager.default.track(et: .change, value: String(describing: self.classForCoder))
    }
}
