//
//  ReceiptParser.swift
//  Purchases
//
//  Created by Andrés Boedo on 7/22/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

struct ReceiptParser {
    private let objectIdentifierParser: ASN1ObjectIdentifierBuilder
    private let containerBuilder: ASN1ContainerBuilder
    private let receiptBuilder: AppleReceiptBuilder

    init() {
        self.objectIdentifierParser = ASN1ObjectIdentifierBuilder()
        self.containerBuilder = ASN1ContainerBuilder()
        self.receiptBuilder = AppleReceiptBuilder()
    }

    func parse(from data: Data) throws -> AppleReceipt {
        let intData = [UInt8](data)

        let asn1Container = try containerBuilder.build(fromPayload: ArraySlice(intData))
        guard let receiptASN1Container = try findASN1Container(withObjectId: .data, inContainer: asn1Container) else {
            throw ReceiptReadingError.dataObjectIdentifierMissing
        }
        let receipt = try receiptBuilder.build(fromASN1Container: receiptASN1Container)
        return receipt
    }
}

private extension ReceiptParser {
    func findASN1Container(withObjectId objectId: ASN1ObjectIdentifier,
                           inContainer container: ASN1Container) throws -> ASN1Container? {
        if container.encodingType == .constructed {
            var currentPayload = container.internalPayload
            for internalContainer in container.internalContainers {
                currentPayload = currentPayload.dropFirst(internalContainer.totalBytes)
                if internalContainer.containerType == .objectIdentifier {
                    let objectIdentifier = objectIdentifierParser.build(fromPayload: internalContainer.internalPayload)
                    if objectIdentifier == objectId {
                        return try containerBuilder.build(fromPayload: currentPayload)
                    }
                } else {
                    let receipt = try findASN1Container(withObjectId: objectId, inContainer: internalContainer)
                    if receipt != nil {
                        return receipt
                    }
                }
            }
        }
        return nil
    }
}
