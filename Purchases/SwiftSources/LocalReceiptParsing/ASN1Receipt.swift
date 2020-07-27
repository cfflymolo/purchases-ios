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

enum InAppPurchaseAttributeType: UInt {
    case quantity = 1701,
         productId = 1702,
         transactionId = 1703,
         originalTransactionId = 1705,
         purchaseDate = 1704,
         originalPurchaseDate = 1706,
         expiresDate = 1708,
         isInIntroOfferPeriod = 1719,
         cancellationDate = 1712,
         webOrderLineItemId = 1711
}
