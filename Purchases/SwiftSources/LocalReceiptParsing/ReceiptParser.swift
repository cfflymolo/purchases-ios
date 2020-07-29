//
//  ReceiptParser.swift
//  Purchases
//
//  Created by Andrés Boedo on 7/22/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

struct ReceiptParser {
    let objectIdentifierParser: ASN1ObjectIdentifierFactory
    let containerFactory: ASN1ContainerFactory
    let receiptFactory: AppleReceiptFactory

    init() {
        self.objectIdentifierParser = ASN1ObjectIdentifierFactory()
        self.containerFactory = ASN1ContainerFactory()
        self.receiptFactory = AppleReceiptFactory()
    }

    func extract(from data: Data) -> AppleReceipt {
        let intData = [UInt8](data)

        let asn1Container = containerFactory.extractASN1(withPayload: ArraySlice(intData))
        let receiptASN1Container = findASN1Container(withObjectId: .data, inContainer: asn1Container)!
        let receipt = receiptFactory.extractReceipt(fromASN1Container: receiptASN1Container)
        return receipt
    }

    func findASN1Container(withObjectId objectId: ASN1ObjectIdentifier,
                           inContainer container: ASN1Container) -> ASN1Container? {
        if container.encodingType == .constructed {
            var currentPayload = container.internalPayload
            for internalContainer in container.internalContainers {
                currentPayload = currentPayload.dropFirst(internalContainer.totalBytes)
                if internalContainer.containerType == .objectIdentifier {
                    let objectIdentifier = objectIdentifierParser.build(fromPayload: internalContainer.internalPayload)
                    if objectIdentifier == objectId {
                        return containerFactory.extractASN1(withPayload: currentPayload)
                    }
                } else {
                    let receipt = findASN1Container(withObjectId: objectId, inContainer: internalContainer)
                    if receipt != nil {
                        return receipt
                    }
                }
            }
        }
        return nil
    }
}
