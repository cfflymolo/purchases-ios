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
        var currentIndex = 0
        let intData = [UInt8](data)
        
        print(intData)
        let firstByte = intData[currentIndex]
        let foundClass = self.extractClass(byte: firstByte)
        print(foundClass)
        let type = extractType(byte: firstByte)
        print(type)
        let encodingType = extractEncodingType(byte: firstByte)
        print(encodingType)
        currentIndex += 1
        
        
        let length = extractLength(data: Array(intData.dropFirst()))
        print(length)
        
        currentIndex += length.totalBytes
        print(currentIndex)
        
        let asn1Container = ASN1Container(containerClass: foundClass,
                                          containerType: type,
                                          encodingType: encodingType,
                                          length: length.value,
                                          payload: Array(intData.suffix(from: currentIndex).prefix(Int(length.value))))
        print(asn1Container)
        
        currentIndex = 0
        
        let internalContainerClass = extractClass(byte: asn1Container.payload.first!)
        let internalContainerType = extractType(byte: asn1Container.payload.first!)
        let internalEncodingType = extractEncodingType(byte: asn1Container.payload.first!)
        currentIndex += 1
        let internalLength = extractLength(data: Array(asn1Container.payload.suffix(from: currentIndex)))
        
        currentIndex += internalLength.totalBytes
        let internalPayload = Array(intData.suffix(from: currentIndex).prefix(Int(internalLength.value)))
        
        let internalContainer = ASN1Container(containerClass: internalContainerClass,
                                              containerType: internalContainerType,
                                              encodingType: internalEncodingType,
                                              length: internalLength.value,
                                              payload: internalPayload)
        print(internalContainer)
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
    
    func extractLength(data: [UInt8]) -> ASN1Length {
        let firstByte = data.first!
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

struct ASN1Container {
    let containerClass: ASN1Class
    let containerType: ASN1Type
    let encodingType: ASN1EncodingType
    let length: UInt
    let payload: [UInt8]
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

