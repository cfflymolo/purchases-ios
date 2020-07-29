//
// Created by Andrés Boedo on 7/29/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation

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

protocol InAppPurchaseExtractableValueType {}

extension String: InAppPurchaseExtractableValueType {}
extension Date: InAppPurchaseExtractableValueType {}
extension Int: InAppPurchaseExtractableValueType {}
extension Bool: InAppPurchaseExtractableValueType {}
extension Data: InAppPurchaseExtractableValueType {}

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