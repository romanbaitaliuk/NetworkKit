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

enum FooEndpoint: EndpointType {
    case testImmediateResponse
    case testDelayedResponse
    case testCancelRequest
    case testWrongJSONFormat
    case testSingleInterceptor
    case testMultipleInterceptors
    case testErrorResponse

    var baseURL: URL {
        return URL(string: "https://google.com")!
    }

    var path: String {
        return "test"
    }

    var httpMethod: HTTPMethod {
        return .get
    }

    var task: HTTPTask {
        return .requestPlain
    }

    var headers: HTTPHeaders {
        return [:]
    }

    var mockResponse: MockResponseType? {
        switch self {
        case .testImmediateResponse:
            let jsonString = "{ \"message\": \"Completed request with immediate response\" }\n"
            let data = jsonString.data(using: .utf8)!
            return .response(201, data)
        case .testDelayedResponse:
            let jsonString = "{ \"message\": \"Completed request with delayed response\" }\n"
            let data = jsonString.data(using: .utf8)!
            return .response(201, data)
        case .testWrongJSONFormat:
            let jsonString = "{ \"message\" \"Completed request with immediate response\" }\n"
            let data = jsonString.data(using: .utf8)!
            return .response(201, data)
        case .testSingleInterceptor:
            let jsonString = "{ \"message\": \"Completed request with single interceptor\" }\n"
            let data = jsonString.data(using: .utf8)!
            return .response(201, data)
        case .testMultipleInterceptors:
            let jsonString = "{ \"message\": \"Completed request with multiple interceptors\" }\n"
            let data = jsonString.data(using: .utf8)!
            return .response(201, data)
        case .testErrorResponse:
            let error = NSError(domain: "Test error response", code: 500, userInfo: nil)
            return .networkError(error)
        default:
            return nil
        }
    }
}
