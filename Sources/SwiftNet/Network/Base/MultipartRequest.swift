//
//  MultipartRequest.swift
//  1800PetMeds-RX-iOS
//
//  Created by Encora on 12/10/24.
//

import Foundation

public extension Data {

    mutating func append(_ string: String,
                         encoding: String.Encoding = .utf8) {
        
        guard let data = string.data(using: encoding) else {
            return
        }
        append(data)
    }
}

public struct MultipartRequest {
    
    public let boundary: String
    
    private let separator: String = "\r\n"
    private var data: Data

    public init(boundary: String = UUID().uuidString) {
        self.boundary = boundary
        self.data = .init()
    }
    
    private mutating func appendBoundarySeparator() {
        data.append("--\(boundary)\(separator)")
    }
    
    private mutating func appendSeparator() {
        data.append(separator)
    }

    private func disposition(_ key: String) -> String {
        "Content-Disposition: form-data; name=\"\(key)\""
    }

    public mutating func add(
        key: String,
        value: String
    ) {
        appendBoundarySeparator()
        data.append(disposition(key) + separator)
        appendSeparator()
        data.append(value + separator)
    }

    public mutating func add(
        key: String,
        fileName: String?,
        fileMimeType: String?,
        fileData: Data
    ) {
        appendBoundarySeparator()
        if let fileName {
            data.append(disposition(key) + "; filename=\"\(fileName)\"" + separator)
        }
        if let fileMimeType {
            data.append("Content-Type: \(fileMimeType)" + separator + separator)
        }
        data.append(fileData)
        appendSeparator()
    }

    public var httpContentTypeHeadeValue: String {
        "multipart/form-data; boundary=\(boundary)"
    }

    public var httpBody: Data {
        var bodyData = data
        bodyData.append("--\(boundary)--")
        return bodyData
    }
}
