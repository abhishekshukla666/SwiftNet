//
//  EndpointFileUpload.swift
//

import Foundation
//import UIKit

protocol EndpointFileUpload {
    var urlPath: String { get }
    var method: RequestMethod { get }
    var header: [String: String]? { get }
//    var body: UIImage { get }
    var fileName: String { get }
}

extension EndpointFileUpload {
    
}

extension EndpointFileUpload {
    
    var url: URL? {
        return URL(string: urlPath)
    }
}
