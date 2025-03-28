//
//  Endpoint.swift
//  1800PetMeds-RX-iOS
//
//  Created by Encora on 02/08/24.
//

import Foundation

protocol Endpoint {
    var path: String { get }
    var method: RequestMethod { get }
    var header: [String: String]? { get }
    var body: BodyType? { get }
    var queryItem: [URLQueryItem]? { get }
    var name: String { get }
}
typealias BodyType = Any // Can be [String: String] or [[String: String]]

extension Endpoint {
    var url: URL? {
        
        let baseUrlString = path
        if queryItem != nil {
            guard let baseUrl = URL(string: baseUrlString) else {
                return nil
            }
            guard var urlComponents = URLComponents(url: baseUrl, resolvingAgainstBaseURL: false) else {
                return nil
            }
            urlComponents.queryItems = queryItem
            urlComponents.percentEncodedQuery = urlComponents.percentEncodedQuery?
                .replacingOccurrences(of: "+", with: "%2B")
            return urlComponents.url
        } else {
            return URL(string: baseUrlString)
        }
    }
}
