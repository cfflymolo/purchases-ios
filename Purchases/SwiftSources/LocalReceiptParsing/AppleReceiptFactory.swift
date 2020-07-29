//
// Created by Andrés Boedo on 7/29/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation

struct AppleReceiptFactory {
    let containerFactory: ASN1ContainerFactory
    let inAppPurchaseFactory: InAppPurchaseFactory

    init() {
        self.containerFactory = ASN1ContainerFactory()
        self.inAppPurchaseFactory = InAppPurchaseFactory()
    }

    func extractReceipt(fromASN1Container container: ASN1Container) -> AppleReceipt {
        let receipt = AppleReceipt()
        guard let internalContainer = container.internalContainers.first else { fatalError() }
        let receiptContainer = containerFactory.extractASN1(withPayload: internalContainer.internalPayload)
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
            let internalContainer = containerFactory.extractASN1(withPayload: payload)
            return String(bytes: internalContainer.internalPayload, encoding: .utf8)!
        case .creationDate,
             .expirationDate:
            let internalContainer = containerFactory.extractASN1(withPayload: payload)
            // todo: use only one date formatter
            let rfc3339DateFormatter = DateFormatter()
            rfc3339DateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ssZ"
            let dateString = String(bytes: internalContainer.internalPayload, encoding: .ascii)!
            return rfc3339DateFormatter.date(from: dateString)!
        case .inApp:
            let internalContainer = containerFactory.extractASN1(withPayload: payload)
            return inAppPurchaseFactory.extractInAppPurchase(fromContainer: internalContainer)
        }
    }
}