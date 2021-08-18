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

public final class NetworkKit: NSObject {
    private var configuration: URLSessionConfiguration?
    private var sslPining: SSLPining?
    public static var shared = NetworkKit()

    public func setup(with configuration: URLSessionConfiguration = .default, sslPingning: SSLPining? = nil) {
        NetworkKit.shared.configuration = configuration
        NetworkKit.shared.sslPining = sslPining
    }

    func buildSession() -> URLSession {
        return URLSession(configuration: self.configuration ?? .default, delegate: self, delegateQueue: nil)
    }
}

extension NetworkKit: URLSessionDelegate {
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let challengeMethod = challenge.protectionSpace.authenticationMethod
        if let sslPining = self.sslPining,
           challengeMethod ==  NSURLAuthenticationMethodServerTrust {
            if let credential = sslPining.getCredentialInProtectionSpace(protetionSpace: challenge.protectionSpace) {
                completionHandler(.useCredential, credential)
            } else {
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
        } else {
            if let trust = challenge.protectionSpace.serverTrust {
                let credential = URLCredential(trust: trust)
                completionHandler(.useCredential, credential)
            } else {
                completionHandler(.performDefaultHandling, nil)
            }
        }
    }
}

