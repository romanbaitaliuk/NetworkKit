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

import XCTest
@testable import NetworkKit

final class HTTPTaskTests: XCTestCase {
    func testRequestPlainTask() {
        let expectation = XCTestExpectation(description: "Execute request with plain task")

        let router = DefaultNetworkRouter<BarEndpoint>(mockBehavior: .immediate)
        router.execute(endpoint: BarEndpoint.testRequestPlainTask, completion: { result in
            switch result {
            case .success(let response):
                let request = response.urlRequest
                XCTAssertNil(request.httpBody)
                expectation.fulfill()
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        })

        wait(for: [expectation], timeout: 1.0)
    }

    func testRequestDataTask() {
        let expectation = XCTestExpectation(description: "Execute request with data task")

        let router = DefaultNetworkRouter<BarEndpoint>(mockBehavior: .immediate)
        router.execute(endpoint: BarEndpoint.testRequestDataTask, completion: { result in
            switch result {
            case .success(let response):
                let request = response.urlRequest
                let recievedBody = String(data: request.httpBody!, encoding: .utf8)
                XCTAssert(recievedBody == "Data object")
                expectation.fulfill()
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        })

        wait(for: [expectation], timeout: 1.0)
    }

    func testRequestJSONEncodableTask() {
        let expectation = XCTestExpectation(description: "Execute request with JSON encodable task")

        let router = DefaultNetworkRouter<BarEndpoint>(mockBehavior: .immediate)
        router.execute(endpoint: BarEndpoint.testRequestJSONEncodableTask, completion: { result in
            switch result {
            case .success(let response):
                let request = response.urlRequest
                let jsonData = request.httpBody!
                let object = try? JSONDecoder().decode(TestObject.self, from: jsonData)
                XCTAssert(object?.message == "Encodable object")
                expectation.fulfill()
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        })

        wait(for: [expectation], timeout: 1.0)
    }

    func testRequestTaskWithEncodedParametersInURL() {
        let expectation = XCTestExpectation(description: "Execute request with encoded parameters in URL task")

        let router = DefaultNetworkRouter<BarEndpoint>(mockBehavior: .immediate)
        router.execute(endpoint: BarEndpoint.testRequestTaskWithEncodedParametersInURL, completion: { result in
            switch result {
            case .success(let response):
                let request = response.urlRequest
                let urlString = request.url?.absoluteString
                XCTAssert(urlString == "https://google.com/test?foo=bar")
                expectation.fulfill()
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        })

        wait(for: [expectation], timeout: 1.0)
    }

    func testRequestTaskWithEncodedParametersInHTTPBody() {
        let expectation = XCTestExpectation(description: "Execute request with encoded parameters in HTTP body task")

        let router = DefaultNetworkRouter<BarEndpoint>(mockBehavior: .immediate)
        router.execute(endpoint: BarEndpoint.testRequestTaskWithEncodedParametersInHTTPBody, completion: { result in
            switch result {
            case .success(let response):
                let request = response.urlRequest
                let httpBodyString = String(data: request.httpBody!, encoding: .utf8)
                XCTAssert(httpBodyString == "foo=bar")
                expectation.fulfill()
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        })

        wait(for: [expectation], timeout: 1.0)
    }
}
