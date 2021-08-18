//
//  File.swift
//  
//
//  Created by Roman Baitaliuk on 26/07/21.
//

import Foundation
@testable import NetworkKit

enum TestEndpoint: EndpointType {
    case test

    var baseURL: URL {
        return URL(string: "https://google.com")!
    }

    var path: String {
        return "test"
    }

    var httpMethod: HTTPMethod {
        .get
    }

    var task: HTTPTask {
        .requestPlain
    }

    var headers: HTTPHeaders {
        [:]
    }

    var mockResponse: MockResponseType? {
        let jsonString = "{ \"message\": \"Completed request with immediate response\" }\n"
        let data = jsonString.data(using: .utf8)!
        return .response(300, data)
    }
}
