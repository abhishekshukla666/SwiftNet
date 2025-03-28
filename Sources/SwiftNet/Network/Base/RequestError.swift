//
//  RequestError.swift
//

import Foundation

// MARK: - Welcome
public struct ResponseData: Decodable {
    public let status: ResponseStatus?
}

// MARK: - Status
public struct ResponseStatus: Decodable {
    public let errorMessages, code: String?
}
extension DecodingError {
    public var prettyDescription: String {
        switch self {
        case let .typeMismatch(type, context):
            "DecodingError.typeMismatch \(type), value \(context.prettyDescription) @ ERROR: \(localizedDescription)"
        case let .valueNotFound(type, context):
            "DecodingError.valueNotFound \(type), value \(context.prettyDescription) @ ERROR: \(localizedDescription)"
        case let .keyNotFound(key, context):
            "DecodingError.keyNotFound \(key), value \(context.prettyDescription) @ ERROR: \(localizedDescription)"
        case let .dataCorrupted(context):
            "DecodingError.dataCorrupted \(context.prettyDescription), @ ERROR: \(localizedDescription)"
        default:
            "DecodingError: \(localizedDescription)"
        }
    }
}

extension DecodingError.Context {
    var prettyDescription: String {
        var result = ""
        if !codingPath.isEmpty {
            result.append(codingPath.map(\.stringValue).joined(separator: "."))
            result.append(": ")
        }
        result.append(debugDescription)
        if
            let nsError = underlyingError as? NSError,
            let description = nsError.userInfo["NSDebugDescription"] as? String
        {
            result.append(description)
        }
        return result
    }
}

public enum RequestError: LocalizedError, Equatable {
    public static func == (lhs: RequestError, rhs: RequestError) -> Bool {
        lhs.errorDescription == rhs.errorDescription
    }
    
    case decode(error: Error)
    case invalidURL
    case noResponse
    case sessionExpired
    case unauthorized
    case unexpectedStatusCode
    case unknown
    case loginRequired
    case invalidCredentials
    case invalidToken
    case invalidAuthorizationCode
    case custom(error: Error)
    case serverError(String)
    case unauthorizedRequest
    
    public var errorDescription: String? {
        switch self {
        case .decode:
            return "Decode error"
        case .invalidURL:
            return "Invalid URL"
        case .noResponse:
            return "No response"
        case .sessionExpired:
            return "Session expired"
        case .unauthorized:
            return "Unauthorized"
        case .unexpectedStatusCode:
            return "Something went wrong."
        case .unknown:
            return "Unknown error"
        case .loginRequired:
            return ""
        case .invalidToken:
            return "Invalid Token"
        case .invalidCredentials:
            return "Invalid Credentials"
        case .custom(let error):
            return error.localizedDescription
        case .serverError(let errorString):
            return errorString
        case .invalidAuthorizationCode:
            return "Invalid authorization code"
        case .unauthorizedRequest:
            return "Unauthorized request"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .decode(let error):
            return error.localizedDescription
        case .invalidURL:
            return "Invalid URL"
        case .noResponse:
            return "No response"
        case .sessionExpired:
            return "Session expired"
        case .unauthorized:
            return "Unauthorized"
        case .unexpectedStatusCode:
            return "Something went wrong."
        case .unknown:
            return "Unknown error"
        case .loginRequired:
            return ""
        case .invalidToken:
            return "Invalid Token"
        case .invalidCredentials:
            return "Invalid Credentials"
        case .custom(let error):
            return error.localizedDescription
        case .serverError(let errorString):
            return errorString
        case .invalidAuthorizationCode:
            return "Invalid authorization code"
        case .unauthorizedRequest:
            return "Unauthorized request"
        }
    }
    
    public static func failureTypeForAuthorization(_ responseData: [String: Any]?) -> Result<String, RequestError> {
        if responseData?["message"] as? String == "Invalid Credentials." {
            return .failure(.invalidCredentials)
        } else if responseData?["detail"] as? String == "Invalid token provided." {
            return .failure(.invalidToken)
        } else if responseData?["message"] as? String == "invalid authorization code" {
            return .failure(.invalidAuthorizationCode)
        } else if let detail = responseData?["detail"] as? String {
            return .failure(.serverError(detail))
        } else {
            return .failure(.unauthorized)
        }
    }
}
