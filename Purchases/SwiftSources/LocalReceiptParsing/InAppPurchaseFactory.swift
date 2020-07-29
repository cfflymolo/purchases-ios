//
// Created by Andrés Boedo on 7/29/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation

struct InAppPurchaseFactory {
    private let containerFactory: ASN1ContainerFactory
    private let dateFormatter: ISO3601DateFormatter

    init() {
        self.containerFactory = ASN1ContainerFactory()
        self.dateFormatter = ISO3601DateFormatter.shared
    }

    func build(fromContainer container: ASN1Container) -> InAppPurchase {
        let inAppPurchase = InAppPurchase()
        for internalContainer in container.internalContainers {
            guard internalContainer.internalContainers.count == 3 else { fatalError() }
            let typeContainer = internalContainer.internalContainers[0]
            let valueContainer = internalContainer.internalContainers[2]

            guard let attributeType = InAppPurchaseAttributeType(rawValue: typeContainer.internalPayload.toUInt())
                else { continue }
            
            if let value = extractInAppPurchaseValue(fromContainer: valueContainer, withType: attributeType) {
                inAppPurchase.setAttribute(attributeType, value: value)
            }
        }
        return inAppPurchase
    }
}

private extension InAppPurchaseFactory {

    func extractInAppPurchaseValue(fromContainer container: ASN1Container,
                                   withType type: InAppPurchaseAttributeType) -> InAppPurchaseExtractableValueType? {
        let internalContainer = containerFactory.build(fromPayload: container.internalPayload)
        guard internalContainer.length.value > 0 else { return nil }

        switch type {
        case .quantity,
             .webOrderLineItemId,
             .productType:
            return internalContainer.internalPayload.toInt()
        case .isInIntroOfferPeriod,
             .isInTrialPeriod:
            return internalContainer.internalPayload.toBool()
        case .productId,
             .transactionId,
             .originalTransactionId,
             .promotionalOfferIdentifier:
            return internalContainer.internalPayload.toString()
        case .cancellationDate,
             .expiresDate,
             .originalPurchaseDate,
             .purchaseDate:
            return internalContainer.internalPayload.toDate(dateFormatter: dateFormatter)
        }
    }
}
