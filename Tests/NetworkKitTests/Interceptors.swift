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
@testable import NetworkKit

struct AuthInterceptor: Interceptor {
    func prepare(_ request: inout URLRequest) {
        request.addValue("Bearer token1", forHTTPHeaderField: "Authorization")
    }

    func process(_ result: inout Result<Response, NetworkError>) {
        guard case .success(let response) = result else {
            return
        }
        var anyHashableHeaders = response.httpURLResponse?.allHeaderFields ?? [AnyHashable: Any]()
        anyHashableHeaders["Authorization"] = "Bearer token2"
        guard let headers = anyHashableHeaders as? [String: String] else {
            return
        }
        let httpURLResponse = HTTPURLResponse(url: response.urlRequest.url!,
                                              statusCode: 200,
                                              httpVersion: nil,
                                              headerFields: headers)
        let newResponse = Response(urlRequest: response.urlRequest, data: response.data!, httpURLResponse: httpURLResponse)
        result = .success(newResponse)
    }
}

struct PingPongInterceptor: Interceptor {
    func prepare(_ request: inout URLRequest) {
        request.addValue("1", forHTTPHeaderField: "Ping")
    }

    func process(_ result: inout Result<Response, NetworkError>) { 
        guard case .success(let response) = result else {
            return
        }
        var anyHashableHeaders = response.httpURLResponse?.allHeaderFields ?? [AnyHashable: Any]()
        anyHashableHeaders["Pong"] = "2"
        guard let headers = anyHashableHeaders as? [String: String] else {
            return
        }
        let httpURLResponse = HTTPURLResponse(url: response.urlRequest.url!,
                                              statusCode: 200,
                                              httpVersion: nil,
                                              headerFields: headers)
        let newResponse = Response(urlRequest: response.urlRequest, data: response.data!, httpURLResponse: httpURLResponse)
        result = .success(newResponse)
    }
}
