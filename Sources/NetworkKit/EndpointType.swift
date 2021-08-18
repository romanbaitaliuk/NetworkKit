/*
 Copyright (C) 2011-2021 Fiserv, Inc. or its affiliates. All rights reserved. This work,
 including its contents and programming, is confidential and its use is
 strictly limited. This work is furnished only for use by duly authorized
 licensees of Fiserv, Inc. or its affiliates, and their designated agents or
 employees responsible for installation or operation of the products. Any other
 use, duplication, or dissemination without the prior written consent of
 Fiserv, Inc. or its affiliates is strictly prohibited. Except as specified by
 the agreement under which the materials are furnished, Fiserv, Inc. and its
 affiliates do not accept any liabilities with respect to the information
 contained herein and are not responsible for any direct, indirect, special,
 consequential or exemplary damages resulting from the use of this information.
 No warranties, either express or implied, are granted or extended by this work
 or the delivery of this work.
 */

import Foundation

public typealias HTTPHeaders = [String: String]

public enum MockResponseType {
    case response(Int, Data)
    case networkError(Error)
}

public protocol EndpointType {
    var baseURL: URL { get }
    var path: String { get }
    var httpMethod: HTTPMethod { get }
    var task: HTTPTask { get }
    var headers: HTTPHeaders { get }
    var mockResponse: MockResponseType? { get }
    var cachePolicy: URLRequest.CachePolicy { get }
    var timeoutInterval: TimeInterval { get }
}

public extension EndpointType {
    var cachePolicy: URLRequest.CachePolicy {
        return .reloadIgnoringLocalCacheData
    }

    var timeoutInterval: TimeInterval {
        return 10.0
    }
}

extension EndpointType {
    func buildRequest() throws -> URLRequest {
        let url = self.baseURL.appendingPathComponent(self.path)
        var request = URLRequest(url: url,
                                 cachePolicy: self.cachePolicy,
                                 timeoutInterval: self.timeoutInterval)
        request.httpMethod = self.httpMethod.rawValue
        for (key, value) in self.headers {
            request.addValue(value, forHTTPHeaderField: key)
        }
        switch self.task {
        case .requestPlain:
            break
        case .requestData(let data):
            request.httpBody = data
        case .requestJSONEncodable(let encodable):
            let parameters = try encodable.dictionary()
            try JSONParameterEncoder().encode(&request, with: parameters)
        case .requestParameters(let parameters, let destination):
            try URLParameterEncoder(destination: destination).encode(&request, with: parameters)
        }
        return request
    }
}

extension Encodable {
    func dictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw NetworkError.encodingFailed(reason: .encodableConversion)
        }
        return dictionary
    }
}
