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

public struct URLEncoding {
    public enum Destination {
        case urlQuery
        case httpBody
    }

    public enum ArrayEncoding {
        case brackets
        case noBrackets

        public func encode(key: String) -> String {
            switch self {
            case .brackets:
                return "\(key)[]"
            case .noBrackets:
                return key
            }
        }
    }

    public enum BoolEncoding {
        case numeric
        case literal

        public func encode(flag: Bool) -> String {
            switch self {
            case .numeric:
                return flag ? "1" : "0"
            case .literal:
                return flag.description
            }
        }
    }

    public let arrayEncoding: ArrayEncoding
    public let boolEncoding: BoolEncoding

    public init(arrayEncoding: ArrayEncoding = .brackets, boolEncoding: BoolEncoding = .literal) {
        self.arrayEncoding = arrayEncoding
        self.boolEncoding = boolEncoding
    }

    public func query(_ parameters: [String: Any]) -> String {
        var components = [(String, String)]()

        for key in parameters.keys.sorted(by: <) {
            let value = parameters[key]!
            components += queryComponents(fromKey: key, value: value)
        }

        return components.map { "\($0)=\($1)" }.joined(separator: "&")
    }

    private func queryComponents(fromKey key: String, value: Any) -> [(String, String)] {
        var components = [(String, String)]()

        if let dictionary = value as? [String: Any] {
            for (innerKey, value) in dictionary {
                components += queryComponents(fromKey: "\(key)[\(innerKey)]", value: value)
            }
        } else if let array = value as? [Any] {
            for value in array {
                components += queryComponents(fromKey: arrayEncoding.encode(key: key), value: value)
            }
        } else if let flag = value as? Bool {
            components.append((key, boolEncoding.encode(flag: flag)))
        } else {
            components.append((key, "\(value)"))
        }

        return components
    }
}
