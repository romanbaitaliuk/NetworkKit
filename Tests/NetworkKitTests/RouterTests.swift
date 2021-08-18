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

final class RouterTests: XCTestCase {
    func testImmediateResponse() {
        let expectation = XCTestExpectation(description: "Execute request with immediate response")
        
        let router = DefaultNetworkRouter<FooEndpoint>(mockBehavior: .immediate)
        router.execute(endpoint: FooEndpoint.testImmediateResponse, completion: { result in
            switch result {
            case .success(let response):
                let response: TestObject? = response.decode()
                XCTAssert(response?.message == "Completed request with immediate response")
                expectation.fulfill()
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        })

        wait(for: [expectation], timeout: 1.0)
    }

    func testDelayedResponse() {
        let expectation = XCTestExpectation(description: "Execute request with delayed response")

        let router = DefaultNetworkRouter<FooEndpoint>(mockBehavior: .delayed(seconds: 3))
        router.execute(endpoint: FooEndpoint.testDelayedResponse, completion: { result in
            switch result {
            case .success(let response):
                let response: TestObject? = response.decode()
                XCTAssert(response?.message == "Completed request with delayed response")
                expectation.fulfill()
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        })

        wait(for: [expectation], timeout: 4.0)
    }

    func testCancelRequest() {
        let expectation = XCTestExpectation(description: "Execute request and cancel it")

        let router = DefaultNetworkRouter<FooEndpoint>(mockBehavior: .delayed(seconds: 3))
        router.execute(endpoint: FooEndpoint.testCancelRequest, completion: { result in
            switch result {
            case .success(_):
                XCTFail("The request should fail")
            case .failure(let error):
                guard case .underlying(let domainError as NSError, nil) = error else {
                    XCTFail("Wrong error casting")
                    return
                }
                XCTAssert(domainError.code == NSURLErrorCancelled)
                expectation.fulfill()
            }
        })

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
            router.cancel()
        })

        wait(for: [expectation], timeout: 5.0)
    }

    func testWrongJSONFormatResponse() {
        let expectation = XCTestExpectation(description: "Execute request with wrong JSON format")

        let router = DefaultNetworkRouter<FooEndpoint>(mockBehavior: .immediate)
        router.execute(endpoint: FooEndpoint.testWrongJSONFormat, completion: { result in
            switch result {
            case .success(let response):
                let response: TestObject? = response.decode()
                XCTAssertNil(response)
                expectation.fulfill()
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        })

        wait(for: [expectation], timeout: 1.0)
    }

    func testSingleInterceptorRequest() {
        let expectation = XCTestExpectation(description: "Execute request with single interceptor")

        let authInterceptor = AuthInterceptor()
        let router = DefaultNetworkRouter<FooEndpoint>(interceptors: [authInterceptor], mockBehavior: .immediate)
        router.execute(endpoint: FooEndpoint.testSingleInterceptor, completion: { result in
            switch result {
            case .success(let response):
                let testResponse: TestObject? = response.decode()
                XCTAssert(testResponse?.message == "Completed request with single interceptor")
                XCTAssert(response.urlRequest.value(forHTTPHeaderField: "Authorization") == "Bearer token1")
                XCTAssert(response.httpURLResponse?.allHeaderFields["Authorization"] as? String == "Bearer token2")
                XCTAssert(response.httpURLResponse?.statusCode == 200)

                expectation.fulfill()
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        })

        wait(for: [expectation], timeout: 1.0)
    }

    func testSingleInterceptorRequestWithoutInterceptor() {
        let expectation = XCTestExpectation(description: "Execute single interceptor request without interceptor")

        let router = DefaultNetworkRouter<FooEndpoint>(mockBehavior: .immediate)
        router.execute(endpoint: FooEndpoint.testSingleInterceptor, completion: { result in
            switch result {
            case .success(let response):
                let testResponse: TestObject? = response.decode()
                XCTAssert(testResponse?.message == "Completed request with single interceptor")
                XCTAssertNil(response.urlRequest.value(forHTTPHeaderField: "Authorization"))
                XCTAssertNil(response.httpURLResponse?.allHeaderFields["Authorization"] as? String)
                XCTAssert(response.httpURLResponse?.statusCode == 201)

                expectation.fulfill()
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        })

        wait(for: [expectation], timeout: 1.0)
    }

    func testMultipleInterceptorsRequest() {
        let expectation = XCTestExpectation(description: "Execute request with multiple interceptors")

        let authInterceptor = AuthInterceptor()
        let pingPongInterceptor = PingPongInterceptor()
        let router = DefaultNetworkRouter<FooEndpoint>(interceptors: [authInterceptor, pingPongInterceptor], mockBehavior: .immediate)
        router.execute(endpoint: FooEndpoint.testMultipleInterceptors, completion: { result in
            switch result {
            case .success(let response):
                let testResponse: TestObject? = response.decode()
                XCTAssert(testResponse?.message == "Completed request with multiple interceptors")

                XCTAssert(response.urlRequest.value(forHTTPHeaderField: "Authorization") == "Bearer token1")
                XCTAssert(response.httpURLResponse?.allHeaderFields["Authorization"] as? String == "Bearer token2")
                XCTAssert(response.urlRequest.value(forHTTPHeaderField: "Ping") == "1")
                XCTAssert(response.httpURLResponse?.allHeaderFields["Pong"] as? String == "2")
                XCTAssert(response.httpURLResponse?.statusCode == 200)

                expectation.fulfill()
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        })

        wait(for: [expectation], timeout: 1.0)
    }

    func testErrorResponse() {
        let expectation = XCTestExpectation(description: "Execute request with error response")

        let router = DefaultNetworkRouter<FooEndpoint>(mockBehavior: .immediate)
        router.execute(endpoint: FooEndpoint.testErrorResponse, completion: { result in
            switch result {
            case .success(_):
                XCTFail("The request should fail")
            case .failure(let networkError):
                guard case .underlying(let error, _) = networkError else {
                    XCTFail("Error should be of .underlying type")
                    return
                }
                let nsError = error as NSError
                XCTAssert(nsError.domain == "Test error response")
                XCTAssert(nsError.code == 500)
                expectation.fulfill()
            }
        })

        wait(for: [expectation], timeout: 1.0)
    }ß
}
