//
//  ReceiptParser.swift
//  Purchases
//
//  Created by Andrés Boedo on 7/22/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

struct ReceiptParser {
    let objectIdentifierParser: ASN1ObjectIdentifierParser

    init() {
        self.objectIdentifierParser = ASN1ObjectIdentifierParser()
    }

    func extract(from data: Data) {
        let intData = [UInt8](data)

        let asn1Container = extractASN1(withPayload: ArraySlice(intData))
    }

    func extractASN1(withPayload payload: ArraySlice<UInt8>) -> ASN1Container {
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
                let internalContainer = extractASN1(withPayload: currentPayload)
                internalContainers.append(internalContainer)
                currentPayload = currentPayload.dropFirst(internalContainer.totalBytes)
                if internalContainer.containerType == .objectIdentifier {
                    guard let objectIdentifier = objectIdentifierParser.extractObjectIdentifier(payload:
                                                                                                internalContainer.internalPayload)
                        else {
                        break
                    }
                    switch objectIdentifier {
                    case .data:
                        extractReceipt(fromPayload: currentPayload)
                    default:
                        break
                    }
                }
            }
        }
        return ASN1Container(containerClass: containerClass,
                             containerType: containerType,
                             encodingType: encodingType,
                             length: length,
                             internalPayload: internalPayload,
                             internalContainers: internalContainers)
    }

    func extractReceipt(fromPayload payload: ArraySlice<UInt8>) {
        let outerContainer = extractASN1(withPayload: payload)
        guard let internalContainer = outerContainer.internalContainers.first else { fatalError() }
        let inAppReceiptContainer = extractASN1(withPayload: internalContainer.internalPayload)
        for inAppReceiptAttribute in inAppReceiptContainer.internalContainers {
            extractInAppReceiptAttribute(inAppReceiptAttribute)
        }
    }

    func extractInAppReceiptAttribute(_ container: ASN1Container) {
        guard container.internalContainers.count == 3 else { fatalError() }
        let typeContainer = container.internalContainers[0]
        let versionContainer = container.internalContainers[1]
        let valueContainer = container.internalContainers[2]
        let attributeType = ReceiptAttributeType(rawValue: Array(typeContainer.internalPayload).toUInt())
        let version = Array(versionContainer.internalPayload).toUInt()
        guard let nonOptionalType = attributeType else {
            print("skipping in app attribute")
            return
        }

        extractReceiptAttributeValue(fromContainer: valueContainer, withType: nonOptionalType)
    }

    func extractReceiptAttributeValue(fromContainer container: ASN1Container,
                                      withType type: ReceiptAttributeType) {
        switch type {
        case .opaqueValue:
            print("opaqueValue")
        case .sha1Hash:
            print("sha1Hash")
        case .applicationVersion,
             .originalApplicationVersion,
             .bundleId:
            let internalContainer = extractASN1(withPayload: container.internalPayload)
            print(String(bytes: internalContainer.internalPayload, encoding: .utf8)!)
        case .creationDate,
             .expirationDate:
            let internalContainer = extractASN1(withPayload: container.internalPayload)
            print(String(bytes: internalContainer.internalPayload, encoding: .ascii)!)
        case .inApp:
            let internalContainer = extractASN1(withPayload: container.internalPayload)
            print(extractInAppPurchase(fromContainer: internalContainer))
        }
    }

    func extractInAppPurchase(fromContainer container: ASN1Container) {
        for internalContainer in container.internalContainers {

            guard internalContainer.internalContainers.count == 3 else { fatalError() }
            let typeContainer = internalContainer.internalContainers[0]
            let versionContainer = internalContainer.internalContainers[1]
            let valueContainer = internalContainer.internalContainers[2]

            guard let attributeType = InAppPurchaseAttributeType(rawValue: Array(typeContainer.internalPayload)
                .toUInt())
                else {
                continue
            }
            let version = Array(versionContainer.internalPayload).toUInt()

            let value = extractInAppPurchaseValue(fromContainer: valueContainer, withType: attributeType)
            print("\(attributeType): \(value)")
        }
    }

    func extractInAppPurchaseValue(fromContainer container: ASN1Container,
                                   withType type: InAppPurchaseAttributeType) -> String {
        switch type {
        case .quantity,
             .webOrderLineItemId:
            let internalContainer = extractASN1(withPayload: container.internalPayload)
            return "\(Array(internalContainer.internalPayload).toUInt())"
        case .isInIntroOfferPeriod:
            let internalContainer = extractASN1(withPayload: container.internalPayload)
            let boolValue = Array(internalContainer.internalPayload).toUInt() == 1
            return "\(boolValue)"
        case .productId,
             .transactionId,
             .originalTransactionId:
            let internalContainer = extractASN1(withPayload: container.internalPayload)
            return String(bytes: internalContainer.internalPayload, encoding: .utf8)!
        case .cancellationDate,
             .expiresDate,
             .originalPurchaseDate,
             .purchaseDate:
            let internalContainer = extractASN1(withPayload: container.internalPayload)
            return String(bytes: internalContainer.internalPayload, encoding: .ascii)!
        }
    }

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
            let byteArray = Array(data.dropFirst().prefix(totalLengthOctets))
            let lengthValue = byteArray.toUInt()
            return ASN1Length(value: lengthValue, totalBytes: totalLengthOctets + 1)
        }
    }
}
