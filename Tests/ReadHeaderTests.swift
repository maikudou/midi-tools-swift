//
//  ReadHeaderTests.swift
//
//
//  Created by Mikhail Labanov on 5/3/24.
//

import XCTest
@testable import MidiToolsSwift

final class ReadHeaderTests: XCTestCase {
    
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
        
        let (bytesRead, header) = try readHeader(
            from: data
        )
        XCTAssertEqual(bytesRead, 14)
        XCTAssertEqual(header, Header(
            length: 6,
            type: 0,
            tracksCount: 1,
            division: Division.metric(DivisionMetric(ticksPerQuarterNote: 480)))
        )
    }
    
    func testValidHeaderType1Tracks3() throws {
        var data = Data()
        data.append(CHUNK_TYPE)
        data.append(LENGTH)
        data.append(Data([0x00, 0x01]))
        data.append(Data([0x00, 0x3]))
        data.append(DIVISION)
        
        let (bytesRead, header) = try readHeader(
            from: data
        )
        XCTAssertEqual(bytesRead, 14)
        XCTAssertEqual(header, Header(
            length: 6,
            type: 1,
            tracksCount: 3,
            division: Division.metric(DivisionMetric(ticksPerQuarterNote: 480)))
        )
    }
    
    func testValidHeaderType2() throws {
        var data = Data()
        data.append(CHUNK_TYPE)
        data.append(LENGTH)
        data.append(Data([0x00, 0x02]))
        data.append(NTRKS)
        data.append(DIVISION)
        
        let (bytesRead, header) = try readHeader(
            from: data
        )
        XCTAssertEqual(bytesRead, 14)
        XCTAssertEqual(header, Header(
            length: 6,
            type: 2,
            tracksCount: 1,
            division: Division.metric(DivisionMetric(ticksPerQuarterNote: 480)))
        )
    }
    
    func testValidHeaderType0Track1SMPTE() throws {
        var data = Data()
        data.append(CHUNK_TYPE)
        data.append(LENGTH)
        data.append(FORMAT)
        data.append(NTRKS)
        data.append(Data([0xE8, 0x50]))
        
        let (bytesRead, header) = try readHeader(
            from: data
        )
        XCTAssertEqual(bytesRead, 14)
        XCTAssertEqual(header, Header(
            length: 6,
            type: 0,
            tracksCount: 1,
            division: Division.timeCode(DivisionTimeCode(fps: 24, ticksPerFrame: 80)))
        )
    }
    
    func testInvalidFileFormat() throws {
        var data = Data()
        data.append(CHUNK_TYPE)
        data.append(LENGTH)
        data.append(Data([0x00, 0x03]))
        data.append(NTRKS)
        data.append(DIVISION)
        
        XCTAssertThrowsError(
            try readHeader(
                from: data
            )
        ) {error in
            XCTAssertEqual(error as! ParseError, ParseError.invalidFileType(fileType: 3))
        }
    }
    
    
    func testTooShortHeader() throws {
        var data = Data()
        data.append(CHUNK_TYPE)
        data = data.subdata(in: Range<Data.Index>(0...2))
        
        XCTAssertThrowsError(
            try readHeader(
                from: data
            )
        ) {error in
            XCTAssertEqual(error as! ParseError, ParseError.outOfBounds)
        }
    }
    
    func testInvalidHeader() throws {
        let data = Data([0x4d, 0x54, 0x68, 0x65])
        
        XCTAssertThrowsError(
            try readHeader(
                from: data
            )
        ) {error in
            XCTAssertEqual(error as! ParseError, ParseError.invalidHeader)
        }
    }
    
    func testValidHeaderWithExtraData() throws {
        var data = Data()
        data.append(CHUNK_TYPE)
        data.append(Data([0x00, 0x00, 0x00, 0x08]))
        data.append(FORMAT)
        data.append(NTRKS)
        data.append(DIVISION)
        data.append(Data([0xff, 0x80]))
        
        let (bytesRead, header) = try readHeader(
            from: data
        )
        XCTAssertEqual(bytesRead, 16)
        XCTAssertEqual(header, Header(
            length: 8,
            type: 0,
            tracksCount: 1,
            division: Division.metric(DivisionMetric(ticksPerQuarterNote: 480)))
        )
    }
}
