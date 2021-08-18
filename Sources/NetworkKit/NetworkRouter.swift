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

public typealias NetworkRouterCompletion = (Result<Response, NetworkError>) -> Void

public protocol NetworkRouter: AnyObject {
    associatedtype Endpoint: EndpointType
    init(interceptors: [Interceptor], mockBehavior: MockBehavior)
    func execute(endpoint: Endpoint, completion: @escaping NetworkRouterCompletion)
    func cancel()
}

public enum MockBehavior: Equatable {
    case never
    case immediate
    case delayed(seconds: Int)
}

public final class DefaultNetworkRouter<Endpoint: EndpointType>: NetworkRouter {
    private var task: URLSessionTask?
    private var mockTask: DispatchWorkItem?
    private lazy var session: URLSession = NetworkKit.shared.buildSession()
    private let interceptors: [Interceptor]
    private let mockBehavior: MockBehavior

    public init(interceptors: [Interceptor] = [], mockBehavior: MockBehavior = .never) {
        self.interceptors = interceptors
        self.mockBehavior = mockBehavior
    }

    public func execute(endpoint: Endpoint, completion: @escaping NetworkRouterCompletion) {
        do {
            var request = try endpoint.buildRequest()
            self.interceptors.forEach { $0.prepare(&request) }

            self.manageRequest(request, mockResponse: endpoint.mockResponse, completion: { result in
                var result = result
                self.interceptors.forEach { $0.process(&result) }
                completion(result)
            })
        } catch {
            var result: Result<Response, NetworkError> = .failure(error as! NetworkError)
            self.interceptors.forEach { $0.process(&result) }
            completion(result)
        }
    }

    public func cancel() {
        switch self.mockBehavior {
        case .never:
            self.task?.cancel()
        case .delayed(seconds: _), .immediate:
            self.mockTask?.cancel()
        }
    }
}

// MARK: - Private methods

private extension DefaultNetworkRouter {
    func manageRequest(_ request: URLRequest, mockResponse: MockResponseType?, completion: @escaping NetworkRouterCompletion) {
        if self.mockBehavior != .never {
            self.mockTask = DispatchWorkItem { [weak self] in
                self?.executeMockRequest(request, mockResponse: mockResponse, completion: completion)
            }

            self.mockTask?.notify(queue: .main, execute: { [weak self] in
                if let mockTask = self?.mockTask, mockTask.isCancelled {
                    let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: nil)
                    completion(.failure(.underlying(error, nil)))
                    return
                }
            })
        }

        switch self.mockBehavior {
        case .never:
            self.executeRealRequest(request, completion: completion)
        case .immediate:
            DispatchQueue.main.async(execute: self.mockTask!)
        case .delayed(seconds: let delay):
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(delay), execute: self.mockTask!)
        }
    }

    func executeRealRequest(_ request: URLRequest, completion: @escaping NetworkRouterCompletion) {
        self.task = self.session.dataTask(with: request, completionHandler: { data, urlResponse, error in
            let response = Response(urlRequest: request, data: data, httpURLResponse: urlResponse as? HTTPURLResponse)
            if let error = error {
                completion(.failure(.underlying(error, response)))
                return
            }
            completion(.success(response))
        })
        self.task?.resume()
    }

    func executeMockRequest(_ request: URLRequest,
                            mockResponse: MockResponseType?,
                            completion: @escaping NetworkRouterCompletion) {
        guard let mockResponse = mockResponse else {
            fatalError("Method called to mock request when no mock response is being provided.")
        }
        switch mockResponse {
        case .response(let code, let mockData):
            let httpURLResponse = HTTPURLResponse(url: request.url!, statusCode: code, httpVersion: nil, headerFields: nil)
            let response = Response(urlRequest: request, data: mockData, httpURLResponse: httpURLResponse)
            completion(.success(response))
        case .networkError(let error):
            completion(.failure(.underlying(error, nil)))
        }
    }
}
