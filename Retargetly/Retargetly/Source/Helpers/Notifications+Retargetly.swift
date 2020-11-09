//
//  Notification+Retargetly.swift
//  Retargetly
//
//  Created by José Valderrama on 24/06/2018.
//  Copyright © 2018 Retargetly. All rights reserved.
//

import Foundation


// TODO: Possible deprecated soon?

extension Notification.Name {
    static let managerReady = NSNotification.Name("managerReady")
}

extension NotificationCenter {
    func observe(name: NSNotification.Name?, object obj: Any?,
                 queue: OperationQueue?, using block: @escaping (Notification) -> ())
        -> NotificationToken
    {
        let token = addObserver(forName: name, object: obj, queue: queue, using: block)
        return NotificationToken(notificationCenter: self, token: token)
    }
}

final class NotificationToken: NSObject {
    let notificationCenter: NotificationCenter
    let token: Any
    
    init(notificationCenter: NotificationCenter = .default, token: Any) {
        self.notificationCenter = notificationCenter
        self.token = token
    }
    
    deinit {
        notificationCenter.removeObserver(token)
    }
}
