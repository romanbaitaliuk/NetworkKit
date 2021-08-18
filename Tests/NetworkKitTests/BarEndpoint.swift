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

enum BarEndpoint: EndpointType {
    case testRequestPlainTask
    case testRequestDataTask
    case testRequestJSONEncodableTask
    case testRequestTaskWithEncodedParametersInURL
    case testRequestTaskWithEncodedParametersInHTTPBody

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
        switch self {
        case .testRequestPlainTask:
            return .requestPlain
        case .testRequestDataTask:
            let data = "Data object".data(using: .utf8)!
            return .requestData(data)
        case .testRequestJSONEncodableTask:
            let encodable = TestObject(message: "Encodable object")
            return .requestJSONEncodable(encodable)
        case .testRequestTaskWithEncodedParametersInURL:
            let parameters = ["foo":"bar"]
            return .requestParameters(parameters, .urlQuery)
        case .testRequestTaskWithEncodedParametersInHTTPBody:
            let parameters = ["foo":"bar"]
            return .requestParameters(parameters, .httpBody)
        }
    }

    var headers: HTTPHeaders {
        return [:]
    }

    var mockResponse: MockResponseType? {
        let jsonString = "{ \"message\": \"Completed request\" }\n"
        let data = jsonString.data(using: .utf8)!
        return .response(201, data)
    }
}
