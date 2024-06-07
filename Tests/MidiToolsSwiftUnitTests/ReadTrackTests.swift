//
//  ReadTrackTests.swift
//  
//
//  Created by Mike Henkel on 5/13/24.
//

import XCTest
@testable import MidiToolsSwift

final class ReadTrackTests: XCTestCase {
    
    // <Track Chunk> = <chunk type> <length> <MTrk event>+

    // MTrk
    let CHUNK_TYPE = Data([0x4d, 0x54, 0x72, 0x6b])
    let LENGTH = Data([0x00, 0x00, 0x00, 0x0b])
    let META_EVENT = Data([0x00, 0xff, 0x7f, 0x03, 0x00, 0x00, 0x40])
    let MIDI_EVENT = Data([0x40, 0x91, 0x56, 0x67])

    func testValidTrack() throws {
        var data = Data()
        data.append(CHUNK_TYPE)
        data.append(LENGTH)
        data.append(META_EVENT)
        data.append(MIDI_EVENT)
        
        let (bytesRead, track) = try readTrack(number: 0, from: data, at: 0)
        
        XCTAssert(bytesRead == 19)
        
        XCTAssert(track.events[0].0 == 0)
        XCTAssertEqual(
            track.events[0].1 as! SequencerSpecificMetaEvent,
            SequencerSpecificMetaEvent(manufacturerId: "000040"))
        
        XCTAssert(track.events[1].0 == 0x40)
        XCTAssertEqual(
            track.events[1].1 as! NoteOnEvent,
            NoteOnEvent(channel: 1, note: 0x56, velocity: 0x67))
    }

}
