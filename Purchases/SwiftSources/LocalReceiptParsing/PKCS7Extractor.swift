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
        print(intData)
        let firstByte = intData.first!
        let foundClass = self.extractClass(byte: firstByte)
        print(foundClass)
        let type = extractType(byte: firstByte)
        print(type)
        let encodingType = extractEncodingType(byte: firstByte)
        print(encodingType)
    }
    
    func extractClass(byte: UInt8) -> ASN1Class {
        let firstTwoBits = (byte >> 6) & 0b11
        return ASN1Class(rawValue: firstTwoBits)!
    }
    
    func extractEncodingType(byte: UInt8) -> ASN1EncodingType {
        let thirdBit = (byte >> 5) & 0b1
        return ASN1EncodingType(rawValue: thirdBit)!
    }
    
    func extractType(byte: UInt8) -> ASN1Type {
        let lastFiveBits = byte & 0b11111
        return ASN1Type(rawValue: lastFiveBits)!
    }
    
    func extractLength(byte: UInt8) {
        if byte == 0 { }
        
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

enum ASN1Length {
    case short(value: Int)
    case long(length: Int, value: Int)
}
