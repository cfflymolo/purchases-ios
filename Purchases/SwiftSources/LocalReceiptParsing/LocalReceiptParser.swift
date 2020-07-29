//
//  LocalReceiptParser.swift
//  Purchases
//
//  Created by Andrés Boedo on 6/29/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

internal enum LocalReceiptParserErrorCode: Int {
    case ReceiptNotFound,
         UnknownError
}

internal class LocalReceiptParser {
    
    func purchasedIntroOfferProductIdentifiers(receiptData: Data) -> Set<String> {
        let receipt = ReceiptParser().extract(from: receiptData)
        
        let productIdentifiers = receipt.inAppPurchases
            .filter { $0.isInIntroOfferPeriod == true  || $0.isInTrialPeriod == true }
            .map { $0.productId! }
        return Set(productIdentifiers)
    }
}
