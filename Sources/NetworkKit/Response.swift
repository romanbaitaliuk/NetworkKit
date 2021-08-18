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

public final class Response {
    public let urlRequest: URLRequest
    public let data: Data?
    public let httpURLResponse: HTTPURLResponse?

    init(urlRequest: URLRequest,
         data: Data?,
         httpURLResponse: HTTPURLResponse?) {
        self.urlRequest = urlRequest
        self.data = data
        self.httpURLResponse = httpURLResponse
    }
}

public extension Response {
    func filter<R: RangeExpression>(statusCodes: R) throws -> Response where R.Bound == Int {
        guard let httpURLResponse = self.httpURLResponse,
              statusCodes.contains(httpURLResponse.statusCode) else {
            throw NetworkError.statusCode(self)
        }
        return self
    }

    func filterSuccessfulStatusCodes() throws -> Response {
        return try self.filter(statusCodes: 200...299)
    }
}

