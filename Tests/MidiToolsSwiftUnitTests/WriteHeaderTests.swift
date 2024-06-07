//
//  WriteHeaderTests.swift
//
//
//  Created by Mike Henkel on 6/5/24.
//

import XCTest
@testable import MidiToolsSwift

final class WriteHeaderTests: XCTestCase {
    
    // MThd
    let CHUNK_TYPE = Data([0x4d, 0x54, 0x68, 0x64])

    // 32-bit big-endian value, most of the time it is 6
    let LENGTH = Data([0x00, 0x00, 0x00, 0x06])

    // 16-bit big-endian word
    let FORMAT = Data([0x00, 0x00])

    // 16-bit big-endian word
    let NTRKS = Data([0x00, 0x01])

    // 16-bit big-endian word
    let DIVISION = Data([0x01, 0xe0])

    func testValidHeaderType0Track1() throws {
        var data = Data()
        data.append(CHUNK_TYPE)
        data.append(LENGTH)
        data.append(FORMAT)
        data.append(NTRKS)
        data.append(DIVISION)
        
        let (_, header) = try readHeader(
            from: data
        )
        XCTAssertEqual(header.rawData, data)
    }
    
    func testValidHeaderType1Tracks3() throws {
        var data = Data()
        data.append(CHUNK_TYPE)
        data.append(LENGTH)
        data.append(Data([0x00, 0x01]))
        data.append(Data([0x00, 0x3]))
        data.append(DIVISION)
        
        let (_, header) = try readHeader(
            from: data
        )
        XCTAssertEqual(header.rawData, data)
    }
    
    func testValidHeaderType2() throws {
        var data = Data()
        data.append(CHUNK_TYPE)
        data.append(LENGTH)
        data.append(Data([0x00, 0x02]))
        data.append(NTRKS)
        data.append(DIVISION)
        
        let (_, header) = try readHeader(
            from: data
        )
        XCTAssertEqual(header.rawData, data)
    }
    
    func testValidHeaderType0Track1SMPTE() throws {
        var data = Data()
        data.append(CHUNK_TYPE)
        data.append(LENGTH)
        data.append(FORMAT)
        data.append(NTRKS)
        data.append(Data([0xE8, 0x50]))
        
        let (_, header) = try readHeader(
            from: data
        )
        XCTAssertEqual(header.rawData, data)
    }
    
    func testValidHeaderWithExtraData() throws {
        var data = Data()
        data.append(CHUNK_TYPE)
        data.append(Data([0x00, 0x00, 0x00, 0x08]))
        data.append(FORMAT)
        data.append(NTRKS)
        data.append(DIVISION)
        data.append(Data([0xff, 0x80]))
        
        let (_, header) = try readHeader(
            from: data
        )
        XCTAssertEqual(header.rawData, data)
    }
}
