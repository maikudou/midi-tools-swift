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

    func testEncodeTextMetaEvent() throws {
        do {
            let text = "Some text in a meta event"
            let event = TextMetaEvent(text: text)
            var data = Data([0xFF, 0x01])
            data.append(encodeVariableQuantity(quantity: UInt32(text.count)))
            data.append(text.data(using: .isoLatin1)!)
            
            XCTAssertEqual(event.rawData, data)
        }
        
        do {
            let text = ""
            let event = TextMetaEvent(text: text)
            var data = Data([0xFF, 0x01])
            data.append(encodeVariableQuantity(quantity: UInt32(text.count)))
            data.append(text.data(using: .isoLatin1)!)
            
            XCTAssertEqual(event.rawData, data)
        }
        
        do {
            let text = "Any amount of text describing anything. It is a good idea to put a text event right at the beginning of a track, with the name of the track, a description of its intended orchestration, and any other information which the user wants to put there. Text events may also occur at other times in a track, to be used as lyrics, or descriptions of cue points. The text in this event should be printable ASCII characters for maximum interchange. However, other character codes using the high-order bit may be used for interchange of files between different programs on the same computer which supports an extended character set. Programs on a computer which does not support non-ASCII characters should ignore those characters."
            let event = TextMetaEvent(text: text)
            var data = Data([0xFF, 0x01])
            data.append(encodeVariableQuantity(quantity: UInt32(text.count)))
            data.append(text.data(using: .isoLatin1)!)
            
            XCTAssertEqual(event.rawData, data)
        }
    }
    
    func testEncodeSequencerSpecificMetaEvent() throws {
        do {
            let event = SequencerSpecificMetaEvent(manufacturerId: "000040")
            let data = Data([0xFF, 0x7F, 0x03, 0x00, 0x00, 0x40])
            
            XCTAssertEqual(event.rawData, data)
        }
        
        do {
            let event = SequencerSpecificMetaEvent(manufacturerId: "45")
            let data = Data([0xFF, 0x7F, 0x01, 0x45])
            
            XCTAssertEqual(event.rawData, data)
        }
        
        do {
            let event = SequencerSpecificMetaEvent(
                manufacturerId: "000040",
                data: Data([0xcc, 0xdd])
            )
            let data = Data([0xFF, 0x7f, 0x05, 0x00, 0x00, 0x40, 0xcc, 0xdd])
            
            XCTAssertEqual(event.rawData, data)
        }
        
        do {
            let event = SequencerSpecificMetaEvent(
                manufacturerId: "40",
                data: Data([0xcc, 0xdd])
            )
            let data = Data([0xFF, 0x7f, 0x03, 0x40, 0xcc, 0xdd])
            
            XCTAssertEqual(event.rawData, data)
        }
        
        do {
            let event = SequencerSpecificMetaEvent(
                manufacturerId: "00ccdd",
                data: Data([0xff])
            )
            let data = Data([0xFF, 0x7f, 0x04, 0x00, 0xcc, 0xdd, 0xff])
            
            XCTAssertEqual(event.rawData, data)
        }
    }
    
    func testSplitEventsByChannel() throws {
        do {
            let initialTrack: [TrackEvent] = [
                (0, NoteOnEvent(channel: 0, note: 100, velocity: 127)),
                (0, NoteOnEvent(channel: 0, note: 150, velocity: 127)),
                (100, NoteOnEvent(channel: 0, note: 127, velocity: 127)),
                (100, NoteOnEvent(channel: 0, note: 128, velocity: 127)),
                (200, NoteOnEvent(channel: 0, note: 129, velocity: 127)),
                (300, NoteOnEvent(channel: 0, note: 130, velocity: 127)),
            ]
            
            let splitEvents = splitEventsByChannel(initialTrack)
            XCTAssert(splitEvents[0]![0].deltaTime == 0)
            XCTAssert(splitEvents[0]![1].deltaTime == 0)
            XCTAssert(splitEvents[0]![2].deltaTime == 100)
            XCTAssert(splitEvents[0]![3].deltaTime == 100)
            XCTAssert(splitEvents[0]![4].deltaTime == 200)
            XCTAssert(splitEvents[0]![5].deltaTime == 300)
        }
        
        do {
            let initialTrack: [TrackEvent] = [
                (0, NoteOnEvent(channel: 0, note: 100, velocity: 127)),
                (0, NoteOnEvent(channel: 1, note: 150, velocity: 127)),
                (100, NoteOnEvent(channel: 0, note: 127, velocity: 127)),
                (100, NoteOnEvent(channel: 1, note: 128, velocity: 127)),
                (200, NoteOnEvent(channel: 0, note: 129, velocity: 127)),
                (300, NoteOnEvent(channel: 1, note: 130, velocity: 127)),
            ]
            
            let splitEvents = splitEventsByChannel(initialTrack)
            XCTAssert(splitEvents[0]![0].deltaTime == 0)
            XCTAssert(splitEvents[0]![1].deltaTime == 100)
            XCTAssert(splitEvents[0]![2].deltaTime == 300)
            XCTAssert(splitEvents[1]![0].deltaTime == 0)
            XCTAssert(splitEvents[1]![1].deltaTime == 200)
            XCTAssert(splitEvents[1]![2].deltaTime == 500)
        }
    }
}
