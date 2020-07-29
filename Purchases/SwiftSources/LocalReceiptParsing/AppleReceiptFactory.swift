//
// Created by Andrés Boedo on 7/29/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation

struct AppleReceiptFactory {
    private let containerFactory: ASN1ContainerFactory
    private let inAppPurchaseFactory: InAppPurchaseFactory

    init() {
        self.containerFactory = ASN1ContainerFactory()
        self.inAppPurchaseFactory = InAppPurchaseFactory()
    }

    func build(fromASN1Container container: ASN1Container) -> AppleReceipt {
        let receipt = AppleReceipt()
        guard let internalContainer = container.internalContainers.first else { fatalError() }
        let receiptContainer = containerFactory.build(fromPayload: internalContainer.internalPayload)
        for receiptAttribute in receiptContainer.internalContainers {
            let typeContainer = receiptAttribute.internalContainers[0]
            let versionContainer = receiptAttribute.internalContainers[1]
            let valueContainer = receiptAttribute.internalContainers[2]
            let attributeType = ReceiptAttributeType(rawValue: Array(typeContainer.internalPayload).toUInt())
            let version = Array(versionContainer.internalPayload).toUInt()
            guard let nonOptionalType = attributeType else {
                print("skipping in app attribute")
                continue
            }
            let value = extractReceiptAttributeValue(fromContainer: valueContainer, withType: nonOptionalType)
            receipt.setAttribute(nonOptionalType, value: value)
        }
        return receipt
    }
}

private extension AppleReceiptFactory {
    func extractReceiptAttributeValue(fromContainer container: ASN1Container,
                                      withType type: ReceiptAttributeType) -> ReceiptExtractableValueType {
        let payload = container.internalPayload
        switch type {
        case .opaqueValue,
             .sha1Hash:
            return Data(payload)
        case .applicationVersion,
             .originalApplicationVersion,
             .bundleId:
            let internalContainer = containerFactory.build(fromPayload: payload)
            return String(bytes: internalContainer.internalPayload, encoding: .utf8)!
        case .creationDate,
             .expirationDate:
            let internalContainer = containerFactory.build(fromPayload: payload)
            return ISO3601DateFormatter.shared.date(fromBytes: internalContainer.internalPayload)!
        case .inApp:
            let internalContainer = containerFactory.build(fromPayload: payload)
            return inAppPurchaseFactory.build(fromContainer: internalContainer)
        }
    }
}