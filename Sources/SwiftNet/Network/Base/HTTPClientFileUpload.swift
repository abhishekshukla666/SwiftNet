////
////  HTTPClientFileUpload.swift
////  1800PetMeds-RX-iOS
////
////  Created by Bibhishan Biradar on 08/10/24.
////
//
//import Foundation
//import SwiftUI
//
//protocol HTTPClientFileUpload {
//    func sendRequest<T: Decodable>(endpoint: EndpointFileUpload,
//                                   responseModel: T.Type) async -> Result<T?, RequestError>
//}
//
//extension HTTPClientFileUpload {
//    
//    func sendRequest<T: Decodable>(endpoint: EndpointFileUpload, responseModel: T.Type) async -> Result<T?, RequestError> {
//        
//        guard let url = endpoint.url else {
//            crashLogApiError(fileUploadEndpoint: endpoint, message: "Invalid URL", error: nil)
//            return .failure(.invalidURL)
//        }
//        
//        var request = URLRequest(url: url)
//        request.httpMethod = endpoint.method.rawValue
//        request.allHTTPHeaderFields = endpoint.header
//        let boundary = UUID().uuidString
//        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
//        
//        var data = Data()
//        
//        // Image data part
//        let imageData = endpoint.body.jpegData(compressionQuality: 0.7)!
//        let filename = "image.jpg"
//        let mimeType = "image/jpeg"
//        
//        data.append("--\(boundary)\r\n".data(using: .utf8)!)
//        data.append("Content-Disposition: form-data; name=\"\(endpoint.fileName)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
//        data.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
//        data.append(imageData)
//        data.append("\r\n".data(using: .utf8)!)
//        // Close boundary
//        
//        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
//        do {
//            print(endpoint.header ?? "")
//            print(endpoint.method.rawValue)
//            print(endpoint.fileName)
//            let (datas, response) = try await URLSession.shared.upload(for: request, from: data)
//            guard let response = response as? HTTPURLResponse else {
//                crashLogApiError(fileUploadEndpoint: endpoint, message: "Invalid response type", error: nil)
//                return .failure(.noResponse)
//            }
//            print(String(data: datas, encoding: .utf8) ?? "")
//            print(response.statusCode)
//            print(response)
//            switch response.statusCode {
//            case 200...299:
//                if response.statusCode == 204 {
//                    print("Success: No content")
//                    return .success(nil)
//                }
//                do {
//                    let decodedResponse = try JSONDecoder().decode(responseModel, from: datas)
//                    return .success(decodedResponse)
//                } catch let error {
//                    crashLogApiError(fileUploadEndpoint: endpoint,
//                                message: "Error decoding response: \(error)",
//                                statusCode: response.statusCode,
//                                error: error)
//                    return .failure(.decode(error: error))
//                }
//            case 303:
//                if let locationHeader = response.allHeaderFields["Location"] as? String {
//                    var code: String?
//                    var usid: String?
//                    
//                    let components = locationHeader.split(separator: "?")
//                    if components.count > 1 {
//                        let params = components[1].split(separator: "&")
//                        code = String(params.last?.split(separator: "=")[1] ?? "")
//                        usid = String(params.first?.split(separator: "=")[1] ?? "")
//                    }
//                    
//                    if let code, let usid {
//                        return .success(nil)
//                    }
//                } else {
//                    let error = NSError(domain: "",
//                                        code: 200,
//                                        userInfo: [ NSLocalizedDescriptionKey: "The Location data couldn’t be read because it isn’t in the correct format."])
//                    return .failure(.decode(error: error))
//                }
//                return .failure(.unknown)
//            default:
//                return .failure(.unexpectedStatusCode)
//            }
//        } catch {
//            return .failure(.custom(error: error))
//        }
//    }
//}
