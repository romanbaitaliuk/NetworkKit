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

public enum SSLPinningCertificateType: String {
    case root, leaf
}

public class SSLPinningConfiguration {
    private(set) var sslCertificates: [String]
    private(set) var sslPinningCertificateType: SSLPinningCertificateType

    init(sslCertificates: [String], sslPinningCertificateType: SSLPinningCertificateType) {
        self.sslCertificates = sslCertificates
        self.sslPinningCertificateType = sslPinningCertificateType
    }
}

public class SSLPining {
    private var sslPinningConfig: SSLPinningConfiguration

    init(sslPinningConfig: SSLPinningConfiguration) {
        self.sslPinningConfig = sslPinningConfig
    }

    public func getCredentialInProtectionSpace(protetionSpace: URLProtectionSpace) -> URLCredential? {
        if let trust = protetionSpace.serverTrust {
            var trustResult = SecTrustResultType.invalid
            let status = SecTrustEvaluate(trust, &trustResult)
            if (status == errSecSuccess) {
                switch trustResult {
                case .recoverableTrustFailure:
                    if self.validatePublicKeyInProtectionSpace(protetionSpace: protetionSpace) {
                        return URLCredential(trust: trust)
                    }
                case .proceed:
                    // If the certificate is invalid kSecTrustResultUnspecified can never be returned. For more information, https://developer.apple.com/library/mac/qa/qa1360/_index.html
                    break
                default:
                    break
                }
            }
        }

        return nil
    }

    private func validatePublicKeyInProtectionSpace(protetionSpace: URLProtectionSpace) -> Bool {
        if let serverPublicKey = self.getPublicKey(fromProtectionSpace: protetionSpace) {
            for certificateString in self.sslPinningConfig.sslCertificates {
                if let localCertificate = self.loadSSLCertificate(fromBase64String: certificateString),
                    let localPublicKey = self.getPublicKey(fromCertificate: localCertificate, andHost: protetionSpace.host),
                   localPublicKey == serverPublicKey {
                    return true
                }
            }
        }
        return false
    }

    private func getPublicKey(fromProtectionSpace protetionSpace: URLProtectionSpace) -> SecKey? {
        if let serverTrust = protetionSpace.serverTrust {
            switch self.sslPinningConfig.sslPinningCertificateType {
            case .root:
                let certCount = SecTrustGetCertificateCount(serverTrust)
                if let cert = SecTrustGetCertificateAtIndex(serverTrust, certCount - 1) {
                    return self.getPublicKey(fromCertificate: cert, andHost: protetionSpace.host)
                }
            case .leaf:
                return SecTrustCopyPublicKey(serverTrust)
            }
        }
        return nil
    }

    private func getPublicKey(fromCertificate secCertificate: SecCertificate, andHost host: String) -> SecKey? {
        let certArray = [secCertificate]
        var optionalTrust: SecTrust?
        let policyInfo = SecPolicyCreateSSL(true, host as CFString)
        let status = SecTrustCreateWithCertificates(certArray as AnyObject,
                                                    policyInfo,
                                                    &optionalTrust)
        if let trust = optionalTrust,
           status == errSecSuccess {
            var trustResult = SecTrustResultType.invalid
            SecTrustEvaluate(trust, &trustResult)

            switch trustResult {
            case SecTrustResultType.recoverableTrustFailure:
                return SecTrustCopyPublicKey(trust)
            case SecTrustResultType.proceed:
                // If the certificate is invalid kSecTrustResultUnspecified can never be returned. For more information, https://developer.apple.com/library/mac/qa/qa1360/_index.html
                break
            case SecTrustResultType.unspecified:
                return SecTrustCopyPublicKey(trust)
            default:
                break
            }
        }
        return nil
    }

    private func loadSSLCertificate(fromBase64String sslCertificateString: String) -> SecCertificate? {
        if let certData = NSData(base64Encoded: sslCertificateString),
           let secCertificate = SecCertificateCreateWithData(kCFAllocatorDefault, certData) {
            return secCertificate
        }
        return nil
    }
}
