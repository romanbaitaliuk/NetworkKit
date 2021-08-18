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

struct URLParameterEncoder: ParameterEncoder {
    private let encoding = URLEncoding()
    private let destination: URLEncoding.Destination

    init(destination: URLEncoding.Destination) {
        self.destination = destination
    }

    func encode(_ request: inout URLRequest, with parameters: Parameters) throws {
        let query = self.encoding.query(parameters)

        switch self.destination {
        case .urlQuery:
            guard let url = request.url else { throw NetworkError.encodingFailed(reason: .missingURL) }

            if var components = URLComponents(url: url,
                                              resolvingAgainstBaseURL: true) {
                components.query = (components.percentEncodedQuery.map { $0 + "&" } ?? "") + query

                guard let newURL = components.url else {
                    throw NetworkError.encodingFailed(reason: .missingURL)
                }
                request.url = newURL
            }
        case .httpBody:
            request.httpBody = query.data(using: .utf8)
        }
    }
}
