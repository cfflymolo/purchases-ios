//
//  ReceiptParsingError.swift
//  Purchases
//
//  Created by Andrés Boedo on 7/30/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

enum ReceiptReadingError: Error {
    case missingReceipt,
         emptyReceipt,
         dataObjectIdentifierMissing,
         asn1ParsingError,
         receiptParsingError,
         inAppParsingError
}

extension ReceiptReadingError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .missingReceipt:
            return "The receipt couldn't be found"
        case .emptyReceipt:
            return "The receipt is empty"
        case .dataObjectIdentifierMissing:
            return "Couldn't find an object identifier of type data in the receipt"
        case .asn1ParsingError:
            return "Error while parsing, payload can't be interpreted as ASN1"
        case .receiptParsingError:
            return "Error while parsing the receipt. One or more attributes are missing."
        case .inAppParsingError:
            return "Error while parsing in-app purchase. One or more attributes are missing or in the wrong format."
        }
    }
}
