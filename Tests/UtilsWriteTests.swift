//
//  UtilsWriteTests.swift
//
//
//  Created by Mikhail Labanov on 5/5/24.
//

import XCTest
@testable import MidiToolsSwift

final class UtilsWriteTests: XCTestCase {
    func testJoiNibbles() throws {
        XCTAssertEqual(joinNibbles(MSN: 0, LSN: 0), 0)
        XCTAssertEqual(joinNibbles(MSN: 0xf, LSN: 0), 0xf0)
        XCTAssertEqual(joinNibbles(MSN: 0, LSN: 0xf), 0x0f)
        XCTAssertEqual(joinNibbles(MSN: 0xff, LSN: 0), 0xf0)
        XCTAssertEqual(joinNibbles(MSN: 0x7f, LSN: 0), 0xf0)
        XCTAssertEqual(joinNibbles(MSN: 0, LSN: 0xff), 0xf)
        XCTAssertEqual(joinNibbles(MSN: 0, LSN: 0x7f), 0xf)
    }
    
    func testEncodeVariableQuantity() throws {
        // values lower than 127
        XCTAssertEqual(encodeVariableQuantity(quantity: 0), Data([0]))
        XCTAssertEqual(encodeVariableQuantity(quantity: 64), Data([0x40]))
        XCTAssertEqual(encodeVariableQuantity(quantity: 127), Data([0x7f]))
        
        // values higher than 127
        XCTAssertEqual(encodeVariableQuantity(quantity: 0x80), Data([0x81, 0x00]))
        XCTAssertEqual(encodeVariableQuantity(quantity: 0x2000), Data([0xc0, 0x00]))
        XCTAssertEqual(encodeVariableQuantity(quantity: 0x3fff), Data([0xff, 0x7f]))
        XCTAssertEqual(encodeVariableQuantity(quantity: 0x4000), Data([0x81, 0x80, 0x00]))
        XCTAssertEqual(encodeVariableQuantity(quantity: 0x100000), Data([0xc0, 0x80, 0x00]))
        XCTAssertEqual(encodeVariableQuantity(quantity: 0x1fffff), Data([0xff, 0xff, 0x7f]))
        XCTAssertEqual(encodeVariableQuantity(quantity: 0x200000), Data([0x81, 0x80, 0x80, 0x00]))
        XCTAssertEqual(encodeVariableQuantity(quantity: 0x08000000), Data([0xc0, 0x80, 0x80, 0x00]))
        XCTAssertEqual(encodeVariableQuantity(quantity: 0x0fffffff), Data([0xff, 0xff, 0xff, 0x7f]))
    }
}
