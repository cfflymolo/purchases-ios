//
// Created by Andrés Boedo on 7/29/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation

struct InAppPurchaseFactory {
    let containerFactory: ASN1ContainerFactory

    init() {
        self.containerFactory = ASN1ContainerFactory()
    }

    func extractInAppPurchase(fromContainer container: ASN1Container) -> InAppPurchase {
        let inAppPurchase = InAppPurchase()
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

            if let value = extractInAppPurchaseValue(fromContainer: valueContainer, withType: attributeType) {
                inAppPurchase.setAttribute(attributeType, value: value)
            }
        }
        return inAppPurchase
    }

    func extractInAppPurchaseValue(fromContainer container: ASN1Container,
                                   withType type: InAppPurchaseAttributeType) -> InAppPurchaseExtractableValueType? {
        let internalContainer = containerFactory.extractASN1(withPayload: container.internalPayload)
        guard internalContainer.length.value > 0 else { return nil }

        switch type {
        case .quantity,
             .webOrderLineItemId,
             .productType:
            return Int(Array(internalContainer.internalPayload).toUInt())
        case .isInIntroOfferPeriod,
             .isInTrialPeriod:
            let boolValue = Array(internalContainer.internalPayload).toUInt() == 1
            return boolValue
        case .productId,
             .transactionId,
             .originalTransactionId,
             .promotionalOfferIdentifier:
            return String(bytes: internalContainer.internalPayload, encoding: .utf8)!
        case .cancellationDate,
             .expiresDate,
             .originalPurchaseDate,
             .purchaseDate:
            // todo: use only one date formatter
            let rfc3339DateFormatter = DateFormatter()
            rfc3339DateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ssZ"
            let dateString = String(bytes: internalContainer.internalPayload, encoding: .ascii)!
            return rfc3339DateFormatter.date(from: dateString)!
        }
    }
}