//
//  WriteMetaEventTests.swift
//  
//
//  Created by Mikhail Labanov on 6/5/24.
//

import XCTest
@testable import MidiToolsSwift

final class WriteMetaEventTests: XCTestCase {

    func testReadSequenceNumber() throws {
        let buffer = Data(Data([0xff, 0x00, 0x02, 0x00, 0x01]))
        let (_, event) = try readMetaEvent(
            from: buffer,
            at: 1
        )
        
        XCTAssertEqual(event.rawData, buffer)
    }
    
    func testShortTextMetaEvents() throws {
        let text = "Some short text"
        for status in [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09] as [UInt8] {
            var buffer = Data([0xff, status, UInt8(text.count)])
            buffer.append(text.data(using: .isoLatin1)!)
            
            let (_, event) = try readMetaEvent(from: buffer, at: 1)
            XCTAssertEqual(event.rawData, buffer)
        }
    }
    
    func testLongTextMetaEvents() throws {
        let text = "Any amount of text describing anything. It is a good idea to put a text event right at the beginning of a track, with the name of the track, a description of its intended orchestration, and any other information which the user wants to put there. Text events may also occur at other times in a track, to be used as lyrics, or descriptions of cue points. The text in this event should be printable ASCII characters for maximum interchange. However, other character codes using the high-order bit may be used for interchange of files between different programs on the same computer which supports an extended character set. Programs on a computer which does not support non-ASCII characters should ignore those characters."
        for status in [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09] as [UInt8] {
            var buffer = Data([0xff, status])
            buffer.append(encodeVariableQuantity(quantity: UInt32(text.count)))
            buffer.append(text.data(using: .isoLatin1)!)
            
            let (_, event) = try readMetaEvent(from: buffer, at: 1)
            
            XCTAssertEqual(event.rawData, buffer)
        }
    }
    
    func testChannelPrefixEvent() throws {
        let buffer = Data([0xff, 0x20, 0x01, 16])
        let (_, event) = try readMetaEvent(from: buffer, at: 1)
        
        XCTAssertEqual(event.rawData, buffer)
    }
    
    func testPortPrefixEvent() throws {
        let buffer = Data([0xff, 0x21, 0x01, 16])
        let (_, event) = try readMetaEvent(from: buffer, at: 1)
        
        XCTAssertEqual(event.rawData, buffer)
    }
    
    func testEndOfTrackMetaEvent() throws {
        let buffer = Data([0xff, 0x2f, 0x00])
        let (_, event) = try readMetaEvent(from: buffer, at: 1)
        
        XCTAssertEqual(event.rawData, buffer)
    }
    
    func testSetTempoMetaEvent() throws {
        let buffer = Data([0xff, 0x51, 0x03, 0x00, 0xc0, 0xff])
        let (_, event) = try readMetaEvent(from: buffer, at: 1)
        
        XCTAssertEqual(event.rawData, buffer)
    }
    
    func testSFMPTEOffsetMetaEvent() throws {
        let buffer = Data([0xff, 0x54, 0x05, 0x01, 0xc2, 0xff, 0xf, 0xcd])
        let (_, event) = try readMetaEvent(from: buffer, at: 1)
        
        XCTAssertEqual(event.rawData, buffer)
    }
    
    func testTimeSignatureMetaEvent() throws {
        let buffer = Data([0xff, 0x58, 0x04, 0x06, 0x03, 0x24, 0x08])
        let (_, event) = try readMetaEvent(from: buffer, at: 1)
        
        XCTAssertEqual(event.rawData, buffer)
    }
    
    func testKeySignatureMetaEvent() throws {
        do {
            let buffer = Data([0xff, 0x59, 0x02, 0xf9, 0x01])
            let (_, event) = try readMetaEvent(from: buffer, at: 1)
            
            XCTAssertEqual(event.rawData, buffer)
        }
        
        do {
            let buffer = Data([0xff, 0x59, 0x02, 0x5, 0x00])
            let (_, event) = try readMetaEvent(from: buffer, at: 1)
            
            XCTAssertEqual(event.rawData, buffer)
        }
       
        do {
            let buffer = Data([0xff, 0x59, 0x02, 0x0, 0x00])
            let (_, event) = try readMetaEvent(from: buffer, at: 1)
            
            XCTAssertEqual(event.rawData, buffer)
        }
    }
    
    func testSequencerSpecificMetaEventNoData3byteId() throws {
        let buffer = Data([0xff, 0x7f, 0x03, 0x00, 0x00, 0x40])
        let (_, event) = try readMetaEvent(from: buffer, at: 1)
        
        XCTAssertEqual(event.rawData, buffer)
    }
    
    func testSequencerSpecificMetaEventNoData1byteId() throws {
        let buffer = Data([0xff, 0x7f, 0x01, 0x45])
        let (_, event) = try readMetaEvent(from: buffer, at: 1)
        
        XCTAssertEqual(event.rawData, buffer)
    }
    
    func testSequencerSpecificMetaEventData3byteId() throws {
        let buffer = Data([0xff, 0x7f, 0x05, 0x00, 0x00, 0x40, 0xcc, 0xdd])
        let (_, event) = try readMetaEvent(from: buffer, at: 1)
        
        XCTAssertEqual(event.rawData, buffer)
    }
    
    func testSequencerSpecificMetaEventData1byteId() throws {
        let buffer = Data([0xff, 0x7f, 0x03, 0x40, 0xcc, 0xdd])
        let (_, event) = try readMetaEvent(from: buffer, at: 1)
        
        XCTAssertEqual(event.rawData, buffer)
    }
    
    func testSequencerSpecificMetaEventData3byteId2() throws {
        let buffer = Data([0xff, 0x7f, 0x04, 0x00, 0xcc, 0xdd, 0xff])
        let (_, event) = try readMetaEvent(from: buffer, at: 1)
        
        XCTAssertEqual(event.rawData, buffer)
    }
    
    func testUnknownMetaEvent() throws {
        let buffer = Data([0xff, 0x22, 0x01, 0x00])
        let (_, event) = try readMetaEvent(from: buffer, at: 1)
        
        XCTAssertEqual(event.rawData, buffer)
    }

}
