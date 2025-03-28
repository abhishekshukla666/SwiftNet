//
//  HTTPClient.swift
//  1800PetMeds-RX-iOS
//
//  Created by Encora on 02/08/24.
//

import Foundation

protocol HTTPClient {
    func sendRequest<T: Decodable>(
        session: URLSession,
        endpoint: Endpoint,
        responseModel: T.Type) async -> Result<T?, RequestError>
}

// swiftlint:disable cyclomatic_complexity
extension HTTPClient {
    
    fileprivate func getRequest(_ url: URL, _ endpoint: Endpoint) -> URLRequest {
        print("---- API URL: ", url.absoluteString)
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.allHTTPHeaderFields = endpoint.header
        request.timeoutInterval = 30
        request.httpBody = prepareRequestBody(endpoint: endpoint)
        return request
    }
    
    fileprivate func handleSucessResponse<T: Decodable>(_ endpoint: Endpoint,
                                                        _ responseModel: T.Type,
                                                        _ response: HTTPURLResponse,
                                                        _ data: Data) async throws -> Result<T?, RequestError> {
        if response.statusCode == 204 {
            
            guard let allHeaderFields = response.allHeaderFields as? [String: String] else {
                print("Success: No content")
                return .success(nil)
            }
            guard let url = response.url else {
                print("Success: No content")
                return .success(nil)
            }
            let cookies = HTTPCookie.cookies(withResponseHeaderFields: allHeaderFields, for: url)
            return .success(cookies.first?.value as? T)
            
        }
        
        
        if response.url?.lastPathComponent == "mypetmed" {
            let decodedString = String(data: data, encoding: .utf8)
            return .success(decodedString as? T)
        }
        
        do {
            let decodedResponse = try JSONDecoder().decode(responseModel, from: data)
            return .success(decodedResponse)
        } catch let error as DecodingError {
            
            print(error.prettyDescription)
            return .failure(.decode(error: error))
        }
    }
    
    fileprivate func defaultErrorHandling<T: Decodable>(_ responseData: [String : Any]?, _ endpoint: any Endpoint, _ response: HTTPURLResponse) -> Result<T?, RequestError> {
        let authFailureType = RequestError.failureTypeForAuthorization(responseData)
        switch authFailureType {
        case .failure(let error):
            return .failure(.custom(error: error))
        case .success:
            return .failure(.unexpectedStatusCode)
        }
    }
    
    fileprivate func handleResponse<T: Decodable>(session: URLSession,
                                                  endpoint: Endpoint,
                                                  responseModel: T.Type,
                                                  response: HTTPURLResponse,
                                                  data: Data) async throws -> Result<T?, RequestError> {
        
        let responseData = self.logAPIResponse(responseData: data)
        
        switch response.statusCode {
        case 200...299:
            return try await handleSucessResponse(endpoint, responseModel, response, data)
        case 302:
            return .failure(.noResponse)
        case 303:
            return .failure(.unknown)
        case 401:
            let authFailureType = RequestError.failureTypeForAuthorization(responseData)
            switch authFailureType {
            case .failure(let error):
                if error == .invalidToken ||
                    error == .sessionExpired ||
                    error == .unauthorized ||
                    error == .unauthorizedRequest {
                    do {
                        try await refreshTokenAndRetry()
                        return await sendRequest(session: session,
                                                 endpoint: endpoint,
                                                 responseModel: responseModel)
                    } catch {
                        return .failure(.custom(error: error))
                    }
                }
                return .failure(error)
            case .success:
                return .failure(.unknown)
            }
            
        default:
            
            return defaultErrorHandling(responseData, endpoint, response)
        }
    }
    
    @available(iOS 15.0, *)
    func sendRequest<T: Decodable>(session: URLSession,
                                   endpoint: Endpoint,
                                   responseModel: T.Type) async -> Result<T?, RequestError> {
        
        guard let url = endpoint.url else {
            return .failure(.invalidURL)
        }
        
        let request = getRequest(url, endpoint)
        
        do {
            let (data, response) = try await session.data(for: request, delegate: CustomSessionDelegate())
            
            guard let response = response as? HTTPURLResponse else {
                return .failure(.noResponse)
            }
            return try await handleResponse(session: session,
                                            endpoint: endpoint,
                                            responseModel: responseModel,
                                            response: response,
                                            data: data)
        } catch {
            return .failure(.custom(error: error))
        }
    }
    
    func logAPIResponse(responseData: Data) -> [String: Any]? {
        do {
            // Try to decode the JSON response from API
            if let json = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any] {
                print("---- API Response: ", json)
                return json
            }
        } catch {
            print("Failed to decode JSON:", error.localizedDescription)
            return nil
        }
        return nil
    }
    
}

extension HTTPClient {
    internal func refreshTokenAndRetry() async throws {
        
    }
    
    fileprivate func guestLogin()  async throws {
        
    }
    
    fileprivate func getAccessToken() async throws {
       
    }
    
    func prepareRequestBody(endpoint: Endpoint) -> Data? {
        if let data = endpoint.body as? Data { return data }
        var isContentTypeApplicationJSON = false
        if let headers = endpoint.header {
            if let contentType = headers.first(where: { $0.key == "Content-Type" })?.value {
                print("Content-Type is: \(contentType)")
                
                if contentType == "application/json" || contentType == "application/json;charset=utf-8" {
                    isContentTypeApplicationJSON = true
                } else if contentType == "application/x-www-form-urlencoded" {
                    isContentTypeApplicationJSON = false
                }
            } else {
                print("Content-Type header not found.")
                isContentTypeApplicationJSON = false
            }
        }
        
        // Handle the body based on its type
        if let body = endpoint.body {
            do {
                if isContentTypeApplicationJSON {
                    // Convert the body to JSON
                    let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
                    print("---- API Parameters: ", String(data: jsonData, encoding: .utf8) ?? "")
                    return jsonData
                } else if let bodyDict = body as? [String: Any] {
                    // URL-encoded format
                    let parameterArray = bodyDict.compactMap { key, value -> String? in
                        if let stringValue = value as? String {
                            return "\(key)=\(stringValue.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
                        }
                        return nil
                    }
                    let parameterString = parameterArray.joined(separator: "&")
                    print("---- API Parameters: ", parameterString)
                    return parameterString.data(using: .utf8)
                } else if let bodyArray = body as? [[String: Any]], isContentTypeApplicationJSON {
                    // Convert the array to JSON
                    let jsonData = try JSONSerialization.data(withJSONObject: bodyArray, options: [])
                    print("---- API Parameters: ", String(data: jsonData, encoding: .utf8) ?? "")
                    return jsonData
                }
            } catch {
                print("Error encoding parameters: \(error)")
                return nil
            }
        }
        return nil
    }
    
}


// Custom URLSessionDelegate to handle redirects
final class CustomSessionDelegate: NSObject, URLSessionTaskDelegate {
    
    // This method is called when a redirect is encountered
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        // To stop following redirects, pass nil to the completionHandler
        completionHandler(nil)
        
        // If you want to follow the redirect, pass the newRequest
        // completionHandler(request)
        
        print("Redirect prevented: \(response.statusCode)")
    }
}
