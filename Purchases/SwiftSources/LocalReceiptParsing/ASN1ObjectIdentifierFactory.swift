//
// Created by Andrés Boedo on 7/28/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation

enum ASN1ObjectIdentifier: String {
    case data = "1.2.840.113549.1.7.1"
    case signedData = "1.2.840.113549.1.7.2"
    case envelopedData = "1.2.840.113549.1.7.3"
    case signedAndEnvelopedData = "1.2.840.113549.1.7.4"
    case digestedData = "1.2.840.113549.1.7.5"
    case encryptedData = "1.2.840.113549.1.7.6"
}

class ASN1ObjectIdentifierFactory {
    func build(fromPayload payload: ArraySlice<UInt8>) -> ASN1ObjectIdentifier? {
        guard let firstByte = payload.first else { fatalError("invalid object identifier") }

        var oidBytes: [UInt] = []
        oidBytes.append(UInt(firstByte / 40))
        oidBytes.append(UInt(firstByte % 40))

        let trailingPayload = payload.dropFirst()
        var currentValue: UInt = 0
        var isShortLength = false
        var isAppendingToLongValue = false
        for byte in trailingPayload {
            isShortLength = byte.bitAtIndex(0) == 0
            let byteValue = UInt(byte.valueInRange(from: 1, to: 7))

            if isAppendingToLongValue {
                currentValue = (currentValue << 7) | byteValue
                if isShortLength {
                    oidBytes.append(currentValue)
                    isAppendingToLongValue = false
                    currentValue = 0
                } else {
                    isAppendingToLongValue = true
                }
            } else {
                if isShortLength {
                    oidBytes.append(byteValue)
                    isAppendingToLongValue = false
                    currentValue = 0
                } else {
                    currentValue = byteValue
                    isAppendingToLongValue = true
                }
            }
        }

        let oidString = oidBytes.map { String($0) }
                                .joined(separator: ".")
        return ASN1ObjectIdentifier(rawValue: oidString)
    }
}