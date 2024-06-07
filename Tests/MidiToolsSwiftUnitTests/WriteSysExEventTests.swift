//
//  WriteSysExEventTests.swift
//  
//
//  Created by Mikhail Labanov on 6/5/24.
//

import XCTest
@testable import MidiToolsSwift

final class WriteSysExEventTests: XCTestCase {
    func testSysexEventParser() throws {
        do {
            let buffer = Data([
              0xf0, 0x2, 0x45, 0xf3
            ])

            let status = try buffer.readUInt8(0)

            let (bytesRead, event) = try readSysExEvent(
                from: buffer, at: 1, withStatus: status
            )
            switch (event) {
            case .initial(let event):
                XCTAssertEqual(event.rawData, buffer)
            case .continued(let event):
                XCTAssertEqual(event.rawData, buffer)
            }
        }
        
        do {
            let buffer = Data([
              0xf7, 0x3, 0x45, 0xf3, 0xdd
            ])

            let status = try buffer.readUInt8(0)

            let (bytesRead, event) = try readSysExEvent(
                from: buffer, at: 1, withStatus: status
            )
            switch (event) {
            case .initial(let event):
                XCTAssertEqual(event.rawData, buffer)
            case .continued(let event):
                XCTAssertEqual(event.rawData, buffer)
            }
        }
    }
}
