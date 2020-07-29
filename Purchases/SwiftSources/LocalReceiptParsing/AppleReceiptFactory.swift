//
// Created by Andrés Boedo on 7/29/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation

struct AppleReceiptFactory {
    private let containerFactory: ASN1ContainerFactory
    private let inAppPurchaseFactory: InAppPurchaseFactory
    private let dateFormatter: ISO3601DateFormatter

    init() {
        self.containerFactory = ASN1ContainerFactory()
        self.inAppPurchaseFactory = InAppPurchaseFactory()
        self.dateFormatter = ISO3601DateFormatter.shared
    }

    func build(fromASN1Container container: ASN1Container) -> AppleReceipt {
        var bundleId: String?
        var applicationVersion: String?
        var originalApplicationVersion: String?
        var opaqueValue: Data?
        var sha1Hash: Data?
        var creationDate: Date?
        var expirationDate: Date?
        var inAppPurchases: [InAppPurchase] = []

        guard let internalContainer = container.internalContainers.first else { fatalError() }
        let receiptContainer = containerFactory.build(fromPayload: internalContainer.internalPayload)
        for receiptAttribute in receiptContainer.internalContainers {
            let typeContainer = receiptAttribute.internalContainers[0]
            let valueContainer = receiptAttribute.internalContainers[2]
            let attributeType = ReceiptAttributeType(rawValue: typeContainer.internalPayload.toUInt())
            guard let nonOptionalType = attributeType else {
                continue
            }
            let payload = valueContainer.internalPayload

            switch nonOptionalType {
            case .opaqueValue:
                opaqueValue = payload.toData()
            case .sha1Hash:
                sha1Hash = payload.toData()
            case .applicationVersion:
                let internalContainer = containerFactory.build(fromPayload: payload)
                applicationVersion = internalContainer.internalPayload.toString()
            case .originalApplicationVersion:
                let internalContainer = containerFactory.build(fromPayload: payload)
                originalApplicationVersion = internalContainer.internalPayload.toString()
            case .bundleId:
                let internalContainer = containerFactory.build(fromPayload: payload)
                bundleId = internalContainer.internalPayload.toString()
            case .creationDate:
                let internalContainer = containerFactory.build(fromPayload: payload)
                creationDate = internalContainer.internalPayload.toDate(dateFormatter: dateFormatter)
            case .expirationDate:
                let internalContainer = containerFactory.build(fromPayload: payload)
                expirationDate = internalContainer.internalPayload.toDate(dateFormatter: dateFormatter)
            case .inApp:
                let internalContainer = containerFactory.build(fromPayload: payload)
                inAppPurchases.append(inAppPurchaseFactory.build(fromContainer: internalContainer))
            }
        }

        guard let nonOptionalBundleId = bundleId,
            let nonOptionalApplicationVersion = applicationVersion,
            let nonOptionalOriginalApplicationVersion = originalApplicationVersion,
            let nonOptionalOpaqueValue = opaqueValue,
            let nonOptionalSha1Hash = sha1Hash,
            let nonOptionalCreationDate = creationDate else {
            fatalError() // todo: replace with custom error
        }

        let receipt = AppleReceipt(bundleId: nonOptionalBundleId,
                                   applicationVersion: nonOptionalApplicationVersion,
                                   originalApplicationVersion: nonOptionalOriginalApplicationVersion,
                                   opaqueValue: nonOptionalOpaqueValue,
                                   sha1Hash: nonOptionalSha1Hash,
                                   creationDate: nonOptionalCreationDate,
                                   expirationDate: expirationDate,
                                   inAppPurchases: inAppPurchases)
        return receipt
    }
}
