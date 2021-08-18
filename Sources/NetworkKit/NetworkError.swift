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

public enum NetworkError: Error {

    /// Indicates encoding failed with reason `EncodingFailureReason`
    case encodingFailed(reason: EncodingFailureReason)

    /// Indicates a response failed with an invalid HTTP status code
    case statusCode(Response)

    /// Indicates a response failed due to an underlying `Error`
    case underlying(Error, Response?)

    public enum EncodingFailureReason {
        case missingURL
        case jsonSerialization
        case encodableConversion
        case underlying(Error)
    }
}

extension NetworkError.EncodingFailureReason: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .missingURL:
            return "Failed to get url from the request"
        case .jsonSerialization:
            return "Failed to create JSON data object"
        case .encodableConversion:
            return "Failed to convert Encodable to dictionary"
        case .underlying(let error):
            return error.localizedDescription
        }
    }
}

extension NetworkError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .encodingFailed(let reason):
            return reason.errorDescription
        case .statusCode:
            return "Status code didn't fall within the given range."
        case .underlying(let error, _):
            return error.localizedDescription
        }
    }
}
