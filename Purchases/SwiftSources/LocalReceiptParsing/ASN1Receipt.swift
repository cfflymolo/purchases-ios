//
//  ASN1Receipt.swift
//  Purchases
//
//  Created by Andrés Boedo on 7/22/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

struct ASN1Receipt {
    let attributes: [ReceiptAttribute]
}

struct ReceiptAttribute {
    let type: ReceiptAttributeType
    let version: UInt
    let value: String
}

enum ReceiptAttributeType: UInt {
    case bundleId = 2,
         applicationVersion = 3,
         opaqueValue = 4,
         sha1Hash = 5,
         creationDate = 12,
         inApp = 17,
         originalApplicationVersion = 19,
         expirationDate = 21
}
