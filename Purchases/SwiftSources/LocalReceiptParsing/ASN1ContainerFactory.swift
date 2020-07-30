//
// Created by Andrés Boedo on 7/29/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation

struct ASN1ContainerFactory {

    func build(fromPayload payload: ArraySlice<UInt8>) throws -> ASN1Container {
        guard payload.count >= 2,
              let firstByte = payload.first else { throw ReceiptReadingError.asn1ParsingError }
        let containerClass = try extractClass(byte: firstByte)
        let encodingType = try extractEncodingType(byte: firstByte)
        let containerType = try extractType(byte: firstByte)
        let length = try extractLength(data: payload.dropFirst())
        let identifierTotalBytes = 1
        let metadataBytes = identifierTotalBytes + length.totalBytes
        
        guard payload.count - metadataBytes >= Int(length.value) else { throw ReceiptReadingError.asn1ParsingError }
        
        let internalPayload = payload.dropFirst(metadataBytes).prefix(Int(length.value))
        var internalContainers: [ASN1Container] = []
        if encodingType == .constructed {
            var currentPayload = internalPayload
            while (currentPayload.count > 0) {
                let internalContainer = try build(fromPayload: currentPayload)
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

    func extractClass(byte: UInt8) throws -> ASN1Class {
        let firstTwoBits = byte.valueInRange(from: 0, to: 1)
        guard let asn1Class = ASN1Class(rawValue: firstTwoBits) else { throw ReceiptReadingError.asn1ParsingError }
        return asn1Class
    }

    func extractEncodingType(byte: UInt8) throws -> ASN1EncodingType {
        let thirdBit = byte.bitAtIndex(2)
        guard let encodingType = ASN1EncodingType(rawValue: thirdBit) else {
            throw ReceiptReadingError.asn1ParsingError
        }
        return encodingType
    }

    func extractType(byte: UInt8) throws -> ASN1Type {
        let lastFiveBits = byte.valueInRange(from: 3, to: 7)
        guard let asn1Type = ASN1Type(rawValue: lastFiveBits) else { throw ReceiptReadingError.asn1ParsingError }
        return asn1Type
    }

    func extractLength(data: ArraySlice<UInt8>) throws -> ASN1Length {
        guard let firstByte = data.first else { throw ReceiptReadingError.asn1ParsingError }

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
