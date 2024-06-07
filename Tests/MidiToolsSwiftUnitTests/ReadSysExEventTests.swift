//
//  SysExEventParserTests.swift
//  
//
//  Created by Mike Henkel on 5/6/24.
//

import XCTest
@testable import MidiToolsSwift

final class ReadSysExEventTests: XCTestCase {
    func testSysexEventParser() throws {
        let buffer = Data([
          0xf0, 0x2, 0x45, 0xf3, 0xf7, 0x3, 0x45, 0xf3, 0xdd, 0xf0, 0x5, 0xFF
        ])

        var position = 0
        var status = try buffer.readUInt8(position)
        position += 1

        let (bytesRead, event) = try readSysExEvent(
            from: buffer, at: position, withStatus: status
        )
        
        XCTAssertEqual(event, SysExEvent.initial(SysExEventInitial(buffer: Data([0x45, 0xf3]))))
        XCTAssertEqual(bytesRead, 3)
        
        position += Int(bytesRead)

        status = try buffer.readUInt8(position)
        position += 1
        
        let (bytesRead2, event2) = try readSysExEvent(
            from: buffer, at: position, withStatus: status
        )
        
        XCTAssertEqual(event2, SysExEvent.continued(SysExEventContinued(buffer: Data([0x45, 0xf3, 0xdd]))))
        XCTAssertEqual(bytesRead2, 4)
        
        position += Int(bytesRead2)
        
        status = try buffer.readUInt8(position)
        position += 1
        
        XCTAssertThrowsError(try readSysExEvent(
            from: buffer, at: position, withStatus: status
        )) {error in
            XCTAssertEqual(error as! ParseError, ParseError.outOfBounds)
        }
    }
}
