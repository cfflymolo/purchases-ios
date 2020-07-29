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

protocol ReceiptExtractableValueType {}

extension String: ReceiptExtractableValueType {}
extension Date: ReceiptExtractableValueType {}
extension Int: ReceiptExtractableValueType {}
extension Bool: ReceiptExtractableValueType {}
extension Data: ReceiptExtractableValueType {}
extension InAppPurchase: ReceiptExtractableValueType {}

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

