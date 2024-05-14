//
//  ReadMetaEventTests.swift
//
//
//  Created by Mikhail Labanov on 5/7/24.
//

import XCTest
@testable import MidiToolsSwift

final class ReadMetaEventTests: XCTestCase {
    
    func testReadSequenceNumber() throws {
        let (bytesRead, event) = try readMetaEvent(
            from: Data([0x00, 0x02, 0x00, 0x01]),
            at: 0
        )
        
        XCTAssertEqual(bytesRead, 4)
        XCTAssertEqual(event as! SequenceNumberMetaEvent,
                       SequenceNumberMetaEvent(sequenceNumber: 1))
    }
    
    func testShortTextMetaEvents() throws {
        let text = "Some short text"
        for status in [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07] as [UInt8] {
            var buffer = Data([status, UInt8(text.count)])
            buffer.append(text.data(using: .isoLatin1)!)
            
            let (bytesRead, event) = try readMetaEvent(from: buffer, at: 0)
            
            XCTAssertEqual(bytesRead, UInt32(text.count + 2))
            XCTAssertEqual(event.type, status)
            XCTAssertEqual((event as! any TextEvent).text, text)
        }
    }
    
    func testLongTextMetaEvents() throws {
        let text = "Any amount of text describing anything. It is a good idea to put a text event right at the beginning of a track, with the name of the track, a description of its intended orchestration, and any other information which the user wants to put there. Text events may also occur at other times in a track, to be used as lyrics, or descriptions of cue points. The text in this event should be printable ASCII characters for maximum interchange. However, other character codes using the high-order bit may be used for interchange of files between different programs on the same computer which supports an extended character set. Programs on a computer which does not support non-ASCII characters should ignore those characters."
        for status in [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07] as [UInt8] {
            var buffer = Data([status])
            buffer.append(encodeVariableQuantity(quantity: UInt32(text.count)))
            buffer.append(text.data(using: .isoLatin1)!)
            
            let (bytesRead, event) = try readMetaEvent(from: buffer, at: 0)
            
            XCTAssertEqual(bytesRead, UInt32(text.count + 3))
            XCTAssertEqual(event.type, status)
            XCTAssertEqual((event as! any TextEvent).text, text)
        }
    }
    
    func testChannelPrefixEvent() throws {
        let (bytesRead, event) = try readMetaEvent(from: Data([0x20, 0x01, 16]), at: 0)
        
        XCTAssertEqual(bytesRead, 3)
        XCTAssertEqual(event as! ChannelPrefixMetaEvent, ChannelPrefixMetaEvent(channelPrefix: 16))
    }
    
    func testEndOfTrackMetaEvent() throws {
        let (bytesRead, event) = try readMetaEvent(from: Data([0x2f, 0x00]), at: 0)
        
        XCTAssertEqual(bytesRead, 2)
        XCTAssertEqual(event as! EndOfTrackMetaEvent, EndOfTrackMetaEvent())
    }
    
    func testSetTempoMetaEvent() throws {
        let (bytesRead, event) = try readMetaEvent(from: Data([0x51, 0x03, 0x00, 0xc0, 0xff]), at: 0)
        
        XCTAssertEqual(bytesRead, 5)
        XCTAssertEqual(event as! SetTempoMetaEvent, SetTempoMetaEvent(
            tempo: Tempo(
                microsecondsPerQuarterNote: 49407,
                beatsPerMinute: 1214
            )
        ))
    }
    
    func testSFMPTEOffsetMetaEvent() throws {
        let (bytesRead, event) = try readMetaEvent(from: Data([0x54, 0x05, 0x01, 0xc2, 0xff, 0xf, 0xcd]), at: 0)
        
        XCTAssertEqual(bytesRead, 7)
        XCTAssertEqual(
            event as! SFMPTEOffsetMetaEvent,
            SFMPTEOffsetMetaEvent(
                offset: SFMPTEOffset(
                    hours: 1,
                    minutes: 194,
                    seconds: 255,
                    frames: 15,
                    fractionalFrames: 205
                )
            )
        )
    }
    
    func testTimeSignatureMetaEvent() throws {
        let (bytesRead, event) = try readMetaEvent(from: Data([0x58, 0x04, 0x06, 0x03, 0x24, 0x08]), at: 0)
        
        XCTAssertEqual(bytesRead, 6)
        XCTAssertEqual(
            event as! TimeSignatureMetaEvent,
            TimeSignatureMetaEvent(
                timeSignature: TimeSignature(
                    numerator: 6,
                    denominator: 8,
                    clocksPerClick: 36,
                    bb: 8
                )
            )
        )
    }
    
    func testKeySignatureMetaEvent() throws {
        let (bytesRead, event) = try readMetaEvent(from: Data([0x59, 0x02, 0xf9, 0x01]), at: 0)
        
        XCTAssertEqual(bytesRead, 4)
        XCTAssertEqual(
            event as! KeySignatureMetaEvent,
            KeySignatureMetaEvent(
                keySignature: KeySignature(
                    flats: 7, sharps: 0, major: false)
            )
        )
        
        let (bytesRead2, event2) = try readMetaEvent(from: Data([0x59, 0x02, 0x5, 0x00]), at: 0)
        
        XCTAssertEqual(bytesRead2, 4)
        XCTAssertEqual(
            event2 as! KeySignatureMetaEvent,
            KeySignatureMetaEvent(
                keySignature: KeySignature(
                    flats: 0, sharps: 5, major: true)
            )
        )
        
        let (bytesRead3, event3) = try readMetaEvent(from: Data([0x59, 0x02, 0x0, 0x00]), at: 0)
        
        XCTAssertEqual(bytesRead3, 4)
        XCTAssertEqual(
            event3 as! KeySignatureMetaEvent,
            KeySignatureMetaEvent(
                keySignature: KeySignature(
                    flats: 0, sharps: 0, major: true)
            )
        )
    }
    
    func testSequencerSpecificMetaEventNoData3byteId() throws {
        let (bytesRead, event) = try readMetaEvent(from: Data([0x7f, 0x03, 0x00, 0x00, 0x40]), at: 0)
        
        XCTAssertEqual(bytesRead, 5)
        XCTAssertEqual(
            event as! SequencerSpecificMetaEvent,
            SequencerSpecificMetaEvent(manufacturerId: "000040")
        )
    }
    
    func testSequencerSpecificMetaEventNoData1byteId() throws {
        let (bytesRead, event) = try readMetaEvent(from: Data([0x7f, 0x01, 0x45]), at: 0)
        
        XCTAssertEqual(bytesRead, 3)
        XCTAssertEqual(
            event as! SequencerSpecificMetaEvent,
            SequencerSpecificMetaEvent(manufacturerId: "45")
        )
    }
    
    func testSequencerSpecificMetaEventData3byteId() throws {
        let (bytesRead, event) = try readMetaEvent(from: Data([0x7f, 0x05, 0x00, 0x00, 0x40, 0xcc, 0xdd]), at: 0)
        
        XCTAssertEqual(bytesRead, 7)
        XCTAssertEqual(
            event as! SequencerSpecificMetaEvent,
            SequencerSpecificMetaEvent(manufacturerId: "000040", data: Data([0xcc, 0xdd]))
        )
    }
    
    func testSequencerSpecificMetaEventData1byteId() throws {
        let (bytesRead, event) = try readMetaEvent(from: Data([0x7f, 0x03, 0x40, 0xcc, 0xdd]), at: 0)
        
        XCTAssertEqual(bytesRead, 5)
        XCTAssertEqual(
           event as! SequencerSpecificMetaEvent,
            SequencerSpecificMetaEvent(manufacturerId: "40", data: Data([0xcc, 0xdd]))
        )
    }
    
    func testSequencerSpecificMetaEventData3byteId2() throws {
        let (bytesRead, event) = try readMetaEvent(from: Data([0x7f, 0x04, 0x00, 0xcc, 0xdd, 0xff]), at: 0)
        
        XCTAssertEqual(bytesRead, 6)
        XCTAssertEqual(
            event as! SequencerSpecificMetaEvent,
            SequencerSpecificMetaEvent(manufacturerId: "00ccdd", data: Data([0xff]))
        )
    }
    
    func testUnknownMetaEvent() throws {
        let (bytesRead, event) = try readMetaEvent(from: Data([0x21, 0x01, 0x00]), at: 0)
        
        XCTAssertEqual(bytesRead, 3)
        XCTAssertEqual(
            event as! UnknownMetaEvent,
            UnknownMetaEvent(type: 0x21, data: Data([0x00]))
        )
    }
}
