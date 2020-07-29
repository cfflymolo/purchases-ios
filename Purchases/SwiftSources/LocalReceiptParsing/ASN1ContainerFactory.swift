//
// Created by Andrés Boedo on 7/29/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation

struct ASN1ContainerFactory {

    func build(fromPayload payload: ArraySlice<UInt8>) -> ASN1Container {
        guard payload.count >= 2,
            let firstByte = payload.first else { fatalError("data format invalid") }
        let containerClass = extractClass(byte: firstByte)
        let encodingType = extractEncodingType(byte: firstByte)
        let containerType = extractType(byte: firstByte)
        let length = extractLength(data: payload.dropFirst())
        let identifierTotalBytes = 1
        let internalPayload = payload.dropFirst(identifierTotalBytes + length.totalBytes).prefix(Int(length.value))
        var internalContainers: [ASN1Container] = []
        if encodingType == .constructed {
            var currentPayload = internalPayload
            while (currentPayload.count > 0) {
                let internalContainer = build(fromPayload: currentPayload)
                internalContainers.append(internalContainer)
                currentPayload = currentPayload.dropFirst(internalContainer.totalBytes)
            }
        }
        return ASN1Container(containerClass: containerClass,
                             containerType: containerType,
                             encodingType: encodingType,
                             length: length,
                             internalPayload: internalPayload,
                             internalContainers: internalContainers)
    }
}

private extension ASN1ContainerFactory {

    func extractClass(byte: UInt8) -> ASN1Class {
        let firstTwoBits = byte.valueInRange(from: 0, to: 1)
        return ASN1Class(rawValue: firstTwoBits)!
    }

    func extractEncodingType(byte: UInt8) -> ASN1EncodingType {
        let thirdBit = byte.bitAtIndex(2)
        return ASN1EncodingType(rawValue: thirdBit)!
    }

    func extractType(byte: UInt8) -> ASN1Type {
        let lastFiveBits = byte.valueInRange(from: 3, to: 7)
        return ASN1Type(rawValue: lastFiveBits)!
    }

    func extractLength(data: ArraySlice<UInt8>) -> ASN1Length {
        guard let firstByte = data.first else { fatalError("data format invalid") }

        let lengthBit = firstByte.bitAtIndex(0)
        let isShortLength = lengthBit == 0

        let firstByteValue = UInt(firstByte.valueInRange(from: 1, to: 7))

        if isShortLength {
            return ASN1Length(value: UInt(firstByte), totalBytes: 1)
        } else {
            let totalLengthOctets = Int(firstByteValue)
            let lengthBytes = data.dropFirst().prefix(totalLengthOctets)
            let lengthValue = lengthBytes.toUInt()
            return ASN1Length(value: lengthValue, totalBytes: totalLengthOctets + 1)
        }
    }
}
