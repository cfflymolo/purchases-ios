//
//  AppleReceipt.swift
//  Purchases
//
//  Created by Andrés Boedo on 7/22/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

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

struct AppleReceipt {
    let bundleId: String
    let applicationVersion: String
    let originalApplicationVersion: String
    let opaqueValue: Data
    let sha1Hash: Data
    let creationDate: Date
    let expirationDate: Date?
    let inAppPurchases: [InAppPurchase]

    func purchasedIntroOfferProductIdentifiers() -> Set<String> {
        let productIdentifiers = inAppPurchases
            .filter { $0.isInIntroOfferPeriod || $0.isInTrialPeriod == true }
            .map { $0.productId }
        return Set(productIdentifiers)
    }

    var asDict: [String: Any] {
        return [
            "bundleId": bundleId,
            "applicationVersion": applicationVersion,
            "originalApplicationVersion": originalApplicationVersion,
            "opaqueValue": opaqueValue,
            "sha1Hash": sha1Hash,
            "creationDate": creationDate,
            "expirationDate": expirationDate ?? "",
            "inAppPurchases": inAppPurchases.map { $0.asDict }
        ]
    }

    var description: String {
        return String(describing: self.asDict)
    }
}

