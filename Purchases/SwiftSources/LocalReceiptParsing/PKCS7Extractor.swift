//
//  PKCS7Extractor.swift
//  Purchases
//
//  Created by Andrés Boedo on 7/22/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

struct PKCS7Extractor {
    func extract(from data: Data) {
        let intData = [UInt8](data)
        
        let asn1Container = ASN1Container(payload: ArraySlice(intData))
    }
}

struct ASN1Container {
    let containerClass: ASN1Class
    let containerType: ASN1Type
    let encodingType: ASN1EncodingType
    let length: ASN1Length
    let internalPayload: ArraySlice<UInt8>
    let identifierTotalBytes = 1
    var totalBytes: Int { return identifierTotalBytes + Int(length.value) + length.totalBytes }
    var internalContainers: [ASN1Container] = []
    var inAppReceiptContainer: [ASN1Container] = []
    
    init(payload: ArraySlice<UInt8>) {
        guard payload.count >= 2,
              let firstByte = payload.first else { fatalError("data format invalid") }
        self.containerClass = ASN1Container.extractClass(byte: firstByte)
        self.encodingType = ASN1Container.extractEncodingType(byte: firstByte)
        self.containerType = ASN1Container.extractType(byte: firstByte)
        self.length = ASN1Container.extractLength(data: payload.dropFirst())
        self.internalPayload = payload.dropFirst(identifierTotalBytes + length.totalBytes).prefix(Int(length.value))
        
        if encodingType == .constructed {
            var currentPayload = internalPayload
            while (currentPayload.count > 0) {
                let internalContainer = ASN1Container(payload: currentPayload)
                internalContainers.append(internalContainer)
                currentPayload = currentPayload.dropFirst(internalContainer.totalBytes)
                if internalContainer.containerType == .objectIdentifier {
                    guard let objectIdentifier = ASN1Container.extractObjectIdentifier(payload: internalContainer.internalPayload) else {
                        break
                    }
                    switch objectIdentifier {
                    case .data:
                        ASN1Container.extractReceipt(fromPayload: currentPayload)
                    default:
                        break
                    }
                }
            }
        }
    }
    
    static func extractReceipt(fromPayload payload: ArraySlice<UInt8>) {
        let outerContainer = ASN1Container(payload: payload)
        guard let internalContainer = outerContainer.internalContainers.first else { fatalError() }
        let inAppReceiptContainer = ASN1Container(payload: internalContainer.internalPayload)
        for inAppReceiptAttribute in inAppReceiptContainer.internalContainers {
            ASN1Container.extractInAppReceiptAttribute(inAppReceiptAttribute)
        }
    }
    
    static func extractInAppReceiptAttribute(_ container: ASN1Container) {
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
        
//        print("found type: \(nonOptionalType)")
//        print("found version: \(version)")

        ASN1Container.extractReceiptAttributeValue(fromContainer: valueContainer, withType: nonOptionalType)
//        print("found value: \(value)")
    }
    
    static func extractReceiptAttributeValue(fromContainer container: ASN1Container,
                                             withType type: ReceiptAttributeType) {
        switch type {
        case .opaqueValue:
            print("opaqueValue")
        case .sha1Hash:
            print("sha1Hash")
        case .applicationVersion,
             .originalApplicationVersion,
             .bundleId:
            let internalContainer = ASN1Container(payload: container.internalPayload)
            print(String(bytes: internalContainer.internalPayload, encoding: .utf8)!)
        case .creationDate,
             .expirationDate:
            let internalContainer = ASN1Container(payload: container.internalPayload)
            print(String(bytes: internalContainer.internalPayload, encoding: .ascii)!)
        case .inApp:
            let internalContainer = ASN1Container(payload: container.internalPayload)
            print(ASN1Container.extractInAppPurchase(fromContainer: internalContainer))
        }
    }
    
    static func extractInAppPurchase(fromContainer container: ASN1Container) {
        for internalContainer in container.internalContainers {
            
            guard internalContainer.internalContainers.count == 3 else { fatalError() }
            let typeContainer = internalContainer.internalContainers[0]
            let versionContainer = internalContainer.internalContainers[1]
            let valueContainer = internalContainer.internalContainers[2]
            
            guard let attributeType = InAppPurchaseAttributeType(rawValue: Array(typeContainer.internalPayload).toUInt())
            else {
                continue
            }
            let version = Array(versionContainer.internalPayload).toUInt()
            
            let value = ASN1Container.extractInAppPurchaseValue(fromContainer: valueContainer, withType: attributeType)
            print("\(attributeType): \(value)")
        }
    }
    
    static func extractInAppPurchaseValue(fromContainer container: ASN1Container,
                                          withType type: InAppPurchaseAttributeType) -> String {
        switch type {
        case .quantity,
             .webOrderLineItemId:
            let internalContainer = ASN1Container(payload: container.internalPayload)
            return "\(Array(internalContainer.internalPayload).toUInt())"
        case .isInIntroOfferPeriod:
            let internalContainer = ASN1Container(payload: container.internalPayload)
            let boolValue = Array(internalContainer.internalPayload).toUInt() == 1
            return "\(boolValue)"
        case .productId,
             .transactionId,
             .originalTransactionId:
            let internalContainer = ASN1Container(payload: container.internalPayload)
            return String(bytes: internalContainer.internalPayload, encoding: .utf8)!
        case .cancellationDate,
             .expiresDate,
             .originalPurchaseDate,
             .purchaseDate:
            let internalContainer = ASN1Container(payload: container.internalPayload)
            return String(bytes: internalContainer.internalPayload, encoding: .ascii)!
        }
    }
    
    static func extractObjectIdentifier(payload: ArraySlice<UInt8>) -> ASN1ObjectIdentifier? {
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
    
    enum ASN1ObjectIdentifier: String {
        case data = "1.2.840.113549.1.7.1"
        case signedData = "1.2.840.113549.1.7.2"
        case envelopedData = "1.2.840.113549.1.7.3"
        case signedAndEnvelopedData = "1.2.840.113549.1.7.4"
        case digestedData = "1.2.840.113549.1.7.5"
        case encryptedData = "1.2.840.113549.1.7.6"
    }
    
    static func extractClass(byte: UInt8) -> ASN1Class {
        let firstTwoBits = byte.valueInRange(from: 0, to: 1)
        return ASN1Class(rawValue: firstTwoBits)!
    }
    
    static func extractEncodingType(byte: UInt8) -> ASN1EncodingType {
        let thirdBit = byte.bitAtIndex(2)
        return ASN1EncodingType(rawValue: thirdBit)!
    }
    
    static func extractType(byte: UInt8) -> ASN1Type {
        let lastFiveBits = byte.valueInRange(from: 3, to: 7)
        return ASN1Type(rawValue: lastFiveBits)!
    }
    
    static func extractLength(data: ArraySlice<UInt8>) -> ASN1Length {
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

enum ASN1Class: UInt8 {
    case universal, application, contextSpecific, `private`
}

enum ASN1Type: UInt8 {
    case endOfContent = 0x00
    case boolean = 1
    case integer = 2
    case bitString = 3
    case octetString = 4
    case null = 5
    case objectIdentifier = 6
    case objectDescriptor = 7
    case external = 8
    case real = 9
    case enumerated = 10
    case embeddedPdv = 11
    case utf8String = 12
    case relativeOid = 13
    case sequence = 16
    case set = 17
    case numericString = 18
    case printableString = 19
    case t61String = 20
    case videotexString = 21
    case ia5String = 22
    case utcTime = 23
    case generalizedTime = 24
    case graphicString = 25
    case visibleString = 26
    case generalString = 27
    case universalString = 28
    case characterString = 29
    case bmpString = 30
}

enum ASN1EncodingType: UInt8 {
    case primitive, constructed
}

struct ASN1Length {
    let value: UInt
    let totalBytes: Int
}
