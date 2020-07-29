//
//  LocalReceiptParserTests.swift
//  PurchasesTests
//
//  Created by Andrés Boedo on 7/1/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Nimble
import XCTest
@testable import Purchases

class LocalReceiptParserTests: XCTestCase {
    
    func testParseReceiptWithCustomReceiptParser() {
        let receiptData = sampleReceiptData()
        
        let receipt = ReceiptParser().extract(from: receiptData)
        print(receipt.description)
    }
}

private extension LocalReceiptParserTests {
    
    func sampleReceiptData() -> Data {
        let receiptText = readFile(named: "base64encodedreceipt")
        guard let receiptData = Data(base64Encoded: receiptText) else { fatalError("couldn't decode file") }
        return receiptData
    }
    
    func readFile(named filename: String) -> String {
        guard let pathString = Bundle(for: type(of: self)).path(forResource: filename, ofType: "txt") else {
            fatalError("\(filename) not found")
        }
        do {
            return try String(contentsOfFile: pathString, encoding: String.Encoding.utf8)
        }
        catch let error {
            fatalError("couldn't read file named \(filename). Error: \(error.localizedDescription)")
        }
    }
}
