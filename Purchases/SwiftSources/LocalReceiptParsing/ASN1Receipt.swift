//
//  ASN1Receipt.swift
//  Purchases
//
//  Created by Andrés Boedo on 7/22/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

class AppleReceipt {
    var bundleId: String?
    var applicationVersion: String?
    var originalApplicationVersion: String?
    var opaqueValue: Data?
    var sha1Hash: Data?
    var creationDate: Date?
    var expirationDate: Date?
    var inAppPurchases: [InAppPurchase] = []

    func setAttribute(_ attribute: ReceiptAttributeType, value: ReceiptExtractableValueType) {
        switch attribute {
        case .bundleId:
            guard value is String, let bundleId = value as? String else { fatalError() }
            self.bundleId = bundleId
        case .applicationVersion:
            guard value is String, let applicationVersion = value as? String else { fatalError() }
            self.applicationVersion = applicationVersion
        case .opaqueValue:
            guard value is Data, let opaqueValue = value as? Data else { fatalError() }
            self.opaqueValue = opaqueValue
        case .sha1Hash:
            guard value is Data, let sha1Hash = value as? Data else { fatalError() }
            self.sha1Hash = sha1Hash
        case .creationDate:
            guard value is Date, let creationDate = value as? Date else { fatalError() }
            self.creationDate = creationDate
        case .expirationDate:
            guard value is Date, let expirationDate = value as? Date else { fatalError() }
            self.expirationDate = expirationDate
        case .originalApplicationVersion:
            guard value is String, let originalApplicationVersion = value as? String else { fatalError() }
            self.originalApplicationVersion = originalApplicationVersion
        case .inApp:
            guard value is InAppPurchase, let inApp = value as? InAppPurchase else { fatalError() }
            self.inAppPurchases.append(inApp)
        }
    }

    var asDict: [String: Any] {
        return [
            "bundleId": bundleId ?? "",
            "applicationVersion": applicationVersion ?? "",
            "originalApplicationVersion": originalApplicationVersion ?? "",
            "opaqueValue": opaqueValue ?? "",
            "sha1Hash": sha1Hash ?? "",
            "creationDate": creationDate ?? "",
            "expirationDate": expirationDate ?? "",
            "inAppPurchases": inAppPurchases.map { $0.asDict }
        ]
    }

    var description: String {
        return String(describing: self.asDict)
    }
}

class InAppPurchase {
    var quantity: Int?
    var productId: String?
    var transactionId: String?
    var originalTransactionId: String?
    var productType: InAppPurchaseProductType?
    var purchaseDate: Date?
    var originalPurchaseDate: Date?
    var expiresDate: Date?
    var cancellationDate: Date?
    var isInTrialPeriod: Bool?
    var isInIntroOfferPeriod: Bool?
    var webOrderLineItemId: Int?
    var promotionalOfferIdentifier: String?

    func setAttribute(_ attribute: InAppPurchaseAttributeType, value: InAppPurchaseExtractableValueType) {
        switch attribute {
        case .quantity:
            guard value is Int, let castedValue = value as? Int else { fatalError() }
            self.quantity = castedValue
        case .productId:
            guard value is String, let castedValue = value as? String else { fatalError() }
            self.productId = castedValue
        case .transactionId:
            guard value is String, let castedValue = value as? String else { fatalError() }
            self.transactionId = castedValue
        case .originalTransactionId:
            guard value is String, let castedValue = value as? String else { fatalError() }
            self.originalTransactionId = castedValue
        case .productType:
            guard let intValue = value as? Int, let productType = InAppPurchaseProductType(rawValue: intValue) else {
                fatalError()
            }
            self.productType = productType
        case .purchaseDate:
            guard value is Date, let castedValue = value as? Date else { fatalError() }
            self.purchaseDate = castedValue
        case .originalPurchaseDate:
            guard value is Date, let castedValue = value as? Date else { fatalError() }
            self.originalPurchaseDate = castedValue
        case .expiresDate:
            guard value is Date, let castedValue = value as? Date else { fatalError() }
            self.expiresDate = castedValue
        case .cancellationDate:
            guard value is Date, let castedValue = value as? Date else { fatalError() }
            self.cancellationDate = castedValue
        case .isInTrialPeriod:
            guard value is Bool, let castedValue = value as? Bool else { fatalError() }
            self.isInTrialPeriod = castedValue
        case .isInIntroOfferPeriod:
            guard value is Bool, let castedValue = value as? Bool else { fatalError() }
            self.isInIntroOfferPeriod = castedValue
        case .webOrderLineItemId:
            guard value is Int, let castedValue = value as? Int else { fatalError() }
            self.webOrderLineItemId = castedValue
        case .promotionalOfferIdentifier:
            guard value is String, let castedValue = value as? String else { fatalError() }
            self.promotionalOfferIdentifier = castedValue
        }
    }

    var asDict: [String: InAppPurchaseExtractableValueType] {
        return [
            "quantity": quantity ?? "",
            "productId": productId ?? "",
            "transactionId": transactionId ?? "",
            "originalTransactionId": originalTransactionId ?? "",
            "promotionalOfferIdentifier": promotionalOfferIdentifier ?? "",
            "purchaseDate": purchaseDate ?? "",
            "productType": productType?.rawValue ?? "",
            "originalPurchaseDate": originalPurchaseDate ?? "",
            "expiresDate": expiresDate ?? "",
            "cancellationDate": cancellationDate ?? "",
            "isInTrialPeriod": isInTrialPeriod ?? "",
            "isInIntroOfferPeriod": isInIntroOfferPeriod ?? "",
            "webOrderLineItemId": webOrderLineItemId ?? ""
        ]
    }

    var description: String {
        return String(describing: self.asDict)
    }
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

protocol ReceiptExtractableValueType {}
protocol InAppPurchaseExtractableValueType {}

extension String: ReceiptExtractableValueType, InAppPurchaseExtractableValueType {}
extension Date: ReceiptExtractableValueType, InAppPurchaseExtractableValueType {}
extension Int: ReceiptExtractableValueType, InAppPurchaseExtractableValueType {}
extension Bool: ReceiptExtractableValueType, InAppPurchaseExtractableValueType {}
extension Data: ReceiptExtractableValueType, InAppPurchaseExtractableValueType {}
extension InAppPurchase: ReceiptExtractableValueType {}

enum InAppPurchaseAttributeType: UInt {
    case quantity = 1701,
         productId = 1702,
         transactionId = 1703,
         purchaseDate = 1704,
         originalTransactionId = 1705,
         originalPurchaseDate = 1706,
         productType = 1707,
         expiresDate = 1708,
         webOrderLineItemId = 1711,
         cancellationDate = 1712,
         isInTrialPeriod = 1713,
         isInIntroOfferPeriod = 1719,
         promotionalOfferIdentifier = 1721
}

enum InAppPurchaseProductType: Int {
    case unknown = -1,
         nonConsumable,
         consumable,
         nonRenewingSubscription,
         autoRenewableSubscription
}
