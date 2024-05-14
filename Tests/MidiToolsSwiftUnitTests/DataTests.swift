//
//  DataTests.swift
//
//
//  Created by Mikhail Labanov on 5/5/24.
//

import XCTest
@testable import MidiToolsSwift

final class DataTests: XCTestCase {
    
    func testReadUInt32BE() throws {
        XCTAssertEqual(try Data([0x00,0x00,0x00,0x1]).readUInt32BE(0), UInt32(1))
        XCTAssertEqual(try Data([0xFF,0xCC,0xFF,0xCC]).readUInt32BE(0), UInt32(0xFFCCFFCC))
        XCTAssertEqual(try Data([0xFF,0xCC,0xFF,0xCC,0x00,0x64]).readUInt32BE(2), UInt32(0xFFCC0064))
        XCTAssertThrowsError(try Data().readUInt32BE(0)) { error in
            XCTAssertEqual(error as! ParseError, ParseError.outOfBounds)
        }
        XCTAssertThrowsError(try Data([0x00,0x00,0x10]).readUInt32BE(0)) { error in
            XCTAssertEqual(error as! ParseError, ParseError.outOfBounds)
        }
        XCTAssertThrowsError(try Data([0x00,0x00,0x00,0x01]).readUInt32BE(2)) { error in
            XCTAssertEqual(error as! ParseError, ParseError.outOfBounds)
        }
    }
    
    func testReadUInt16BE() throws {
        XCTAssertEqual(try Data([0x00,0x1]).readUInt16BE(0), UInt16(1))
        XCTAssertEqual(try Data([0xFF,0xCC]).readUInt16BE(0), UInt16(0xFFCC))
        XCTAssertEqual(try Data([0xFF,0xCC,0x64,0xBA]).readUInt16BE(2), UInt16(0x64BA))
        XCTAssertThrowsError(try Data().readUInt16BE(0)) { error in
            XCTAssertEqual(error as! ParseError, ParseError.outOfBounds)
        }
        XCTAssertThrowsError(try Data([0x10]).readUInt16BE(0)) { error in
            XCTAssertEqual(error as! ParseError, ParseError.outOfBounds)
        }
        XCTAssertThrowsError(try Data([0x00,0x01]).readUInt16BE(2)) { error in
            XCTAssertEqual(error as! ParseError, ParseError.outOfBounds)
        }
    }
    
    func testReadUInt8() throws {
        XCTAssertEqual(try Data([0x00,0x1]).readUInt8(0), UInt8(0))
        XCTAssertEqual(try Data([0x00,0x1]).readUInt8(1), UInt8(1))
        XCTAssertEqual(try Data([0xFF,0xCC]).readUInt8(0), UInt8(0xFF))
        XCTAssertEqual(try Data([0xFF,0xCC,0x64,0xBA]).readUInt8(2), UInt8(0x64))
        XCTAssertThrowsError(try Data().readUInt8(0)) { error in
            XCTAssertEqual(error as! ParseError, ParseError.outOfBounds)
        }
        XCTAssertThrowsError(try Data([0x10]).readUInt8(1)) { error in
            XCTAssertEqual(error as! ParseError, ParseError.outOfBounds)
        }
    }
    
    func testReadInt8() throws {
        XCTAssertEqual(try Data([0x00,0x1]).readInt8(0), Int8(0))
        XCTAssertEqual(try Data([0x00,0x1]).readInt8(1), Int8(1))
        XCTAssertEqual(try Data([0xFF,0xCC]).readInt8(0), Int8(-1))
        XCTAssertEqual(try Data([0xE8]).readInt8(0), Int8(-24))
        XCTAssertThrowsError(try Data().readInt8(0)) { error in
            XCTAssertEqual(error as! ParseError, ParseError.outOfBounds)
        }
        XCTAssertThrowsError(try Data([0x10]).readInt8(1)) { error in
            XCTAssertEqual(error as! ParseError, ParseError.outOfBounds)
        }
    }
    
    func testRead7bitWordLE() throws {
        let buffer = Data([0x00, 0x81, 0x7f, 0x7f, 0xff, 0xff, 0x00, 0x40])
        
        XCTAssertEqual(try buffer.read7bitWordLE(0), 0x80)
        XCTAssertEqual(try buffer.read7bitWordLE(2), 0x3fff)
        XCTAssertEqual(try buffer.read7bitWordLE(4), 0x3fff)
        XCTAssertEqual(try buffer.read7bitWordLE(6), 0x2000)
        
        XCTAssertThrowsError(try Data().read7bitWordLE(0)) { error in
            XCTAssertEqual(error as! ParseError, ParseError.outOfBounds)
        }
        XCTAssertThrowsError(try Data([0x10]).read7bitWordLE(10)) { error in
            XCTAssertEqual(error as! ParseError, ParseError.outOfBounds)
        }
    }
    
    func testReadVariableQuantity() throws {
        let buffer = Data([
            0x00, 0x40, 0x7f, 0x81, 0x00, 0xc0, 0x00, 0xff, 0x7f, 0x81, 0x80, 0x00,
            0xc0, 0x80, 0x00, 0xff, 0xff, 0x7f, 0x81, 0x80, 0x80, 0x00, 0xc0, 0x80,
            0x80, 0x00, 0xff, 0xff, 0xff, 0x7f
        ])
        
        let options: [(position: Data.Index, bytesRead: UInt32, result: UInt32)] = [
            (0, 1, 0x00),
            (1, 1, 0x40),
            (2, 1, 0x7F),
            (3, 2, 0x80),
            (5, 2, 0x2000),
            (7, 2, 0x3FFF),
            (9, 3, 0x4000),
            (12, 3, 0x100000),
            (15, 3, 0x1fffff),
            (18, 4, 0x200000),
            (22, 4, 0x08000000),
            (26, 4, 0x0fffffff)
        ]
        
        for option in options {
            let (bytesRead, quantity) = try buffer.readVariableQuantity(option.position)
            XCTAssertEqual(bytesRead, option.bytesRead)
            XCTAssertEqual(quantity, option.result)
        }
    }
}
