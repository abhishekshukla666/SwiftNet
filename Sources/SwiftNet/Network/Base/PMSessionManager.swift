//
//  PMSessionManager.swift
//  1800PetMeds-RX-iOS
//
//  Created by Encora on 02/10/24.
//

import Foundation

extension URLSession {
    static let shared: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30 // seconds
        configuration.timeoutIntervalForResource = 30 // seconds
        return URLSession(configuration: configuration)
    }()
}
