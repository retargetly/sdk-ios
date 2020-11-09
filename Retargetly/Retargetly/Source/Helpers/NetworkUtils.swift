//
//  NetworkUtils.swift
//  Retargetly
//
//  Created by José Valderrama on 6/6/18.
//  Copyright © 2018 Retargetly. All rights reserved.
//

import Foundation

// TODO: Possible deprecated soon?
@objcMembers
public class NetworkUtils {
    
    private init(){}
    
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
