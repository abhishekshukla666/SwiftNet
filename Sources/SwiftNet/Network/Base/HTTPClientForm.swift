//
////  HTTPClientForm.swift
////  1800PetMeds-RX-iOS
////
////  Created by Encora on 12/10/24.
////
//
//import Foundation
//
//struct StatusResponseData {
//    
//}
//
//extension HTTPClient {
//    func sendFormRequest<T: Decodable>(session: URLSession,
//                                       endpoint: Endpoint, model: SignUpModel,
//                                       responseModel: T.Type) async -> Result<T?, RequestError> {
//        
//        guard let url = endpoint.url else {
//            crashLogAPIError(endpoint: endpoint, message: "Invalid URL", error: nil)
//            return .failure(.invalidURL)
//        }
//        
//        print("---- API URL: ", url.absoluteString)
//        
//        var multipart = MultipartRequest()
//        for field in [
//            "email": "\(model.email)",
//            "confirmEmail": "\(model.email)",
//            "password": "\(model.password)",
//            "confirmPassword": "\(model.confirmPassword)",
//            "shippingAddressFirstName": "\(model.firstName)",
//            "shippingAddressLastName": "\(model.lastName)",
//            "shippingAddressPhoneNumber": "\(model.phone ?? "")",
//            "smsOptIn": "\(model.isSMSOptIn)"
//        ] {
//            multipart.add(key: field.key, value: field.value)
//        }
//
//        multipart.add(
//            key: "file",
//            fileName: nil,
//            fileMimeType: nil,
//            fileData: multipart.httpBody
//        )
//        
//        /// Create a regular HTTP URL request & use multipart components
//        var request = URLRequest(url: url)
//        request.httpMethod = endpoint.method.rawValue
//        request.allHTTPHeaderFields = endpoint.header
//        request.setValue(multipart.httpContentTypeHeadeValue, forHTTPHeaderField: "Content-Type")
//        request.httpBody = multipart.httpBody
//        
//        /// Fire the request using URL sesson or anything else...
//        do {
//            let (data, response) = try await URLSession.shared.data(for: request)
//            let responseData = self.logAPIResponse(responseData: data)
//            
//            guard let response = response as? HTTPURLResponse else {
//                crashLogAPIError(endpoint: endpoint, message: "Invalid response type", error: nil)
//                return .failure(.noResponse)
//            }
//            
//            switch response.statusCode {
//            case 200...299:
//                do {
//                    let decodedResponse = try JSONDecoder().decode(responseModel, from: data)
//                    return .success(decodedResponse)
//                } catch let error as DecodingError {
//                    crashLogAPIError(endpoint: endpoint,
//                                message: "Error decoding response: \(error.prettyDescription)",
//                                statusCode: response.statusCode,
//                                error: error)
//                    return .failure(.decode(error: error))
//                }
//            case 401:
//                let authFailureType = RequestError.failureTypeForAuthorization(responseData)
//                switch authFailureType {
//                case .failure(let error):
//                    if error == .invalidToken {
//                        do {
//                            try await refreshTokenAndRetry()
//                            return await sendRequest(session: session,
//                                                     endpoint: endpoint,
//                                                     responseModel: responseModel)
//                        } catch {
//                            crashLogAPIError(endpoint: endpoint,
//                                        message: "Token/Session Error",
//                                        statusCode: response.statusCode,
//                                        error: error)
//                            return .failure(.custom(error: error))
//                        }
//                    }
//                    crashLogAPIError(endpoint: endpoint,
//                                message: "Authorization Error",
//                                statusCode: response.statusCode,
//                                error: error)
//                    return .failure(error)
//                case .success: return .failure(.unknown)
//                }
//            default:
//                crashLogAPIError(endpoint: endpoint,
//                            message: "Authorization Error",
//                            statusCode: response.statusCode,
//                            error: nil)
//                return .failure(.unexpectedStatusCode)
//            }
//        } catch {
//            crashLogAPIError(endpoint: endpoint,
//                        message: "Failed to request Create Account API",
//                        error: error)
//            return .failure(.custom(error: error))
//        }
//        
//    }
//}
