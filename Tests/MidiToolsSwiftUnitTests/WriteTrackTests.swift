//
//  WriteTrackTests.swift
//  
//
//  Created by Mikhail Labanov on 6/5/24.
//

import XCTest
@testable import MidiToolsSwift

final class WriteTrackTests: XCTestCase {

    func testTrackRawDataEmptyTrack() throws {
        let TRACK_CHUNK_TYPE = Data([0x4d, 0x54, 0x72, 0x6b])
        
        do {
            let trackEvents: [TrackEvent] = []
            let track = Track(number: 0, events: trackEvents)
            var data = Data()
            data.append(TRACK_CHUNK_TYPE)
            data.append(Data([0x00,0x00,0x00,0x00]))
            XCTAssertEqual(track.rawData, data)
        }
    }
    
    func testValidTrack() throws {
        let CHUNK_TYPE = Data([0x4d, 0x54, 0x72, 0x6b])
        let LENGTH = Data([0x00, 0x00, 0x00, 0x0b])
        let META_EVENT = Data([0x00, 0xff, 0x7f, 0x03, 0x00, 0x00, 0x40])
        let MIDI_EVENT = Data([0x40, 0x91, 0x56, 0x67])

        var data = Data()
        data.append(CHUNK_TYPE)
        data.appendUInt32BE(UInt32(META_EVENT.count + MIDI_EVENT.count))
        data.append(META_EVENT)
        data.append(MIDI_EVENT)
        
        let (_, track) = try readTrack(number: 0, from: data, at: 0)
        
        XCTAssertEqual(track.rawData, data)
    }
}
