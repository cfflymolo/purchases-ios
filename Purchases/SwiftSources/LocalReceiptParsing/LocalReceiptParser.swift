//
//  LocalReceiptParser.swift
//  Purchases
//
//  Created by Andrés Boedo on 6/29/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

enum LocalReceiptParserErrorCode: Int {
    case ReceiptNotFound,
         UnknownError
}

class LocalReceiptParser {
    
    func purchasedIntroOfferProductIdentifiers(receiptData: Data) -> Set<String> {
        let receipt = ReceiptParser().parse(from: receiptData)
        
        return receipt.purchasedIntroOfferProductIdentifiers()
    }
}
