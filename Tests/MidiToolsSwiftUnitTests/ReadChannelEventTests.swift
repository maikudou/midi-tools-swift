//
//  ReadChannelEventTests.swift
//
//
//  Created by Mikhail Labanov on 5/9/24.
//

import XCTest
@testable import MidiToolsSwift

final class ReadChannelEventTests: XCTestCase {
    
    func testReadNoteOnEvent() throws {
        let buffer = Data([0x90, 0x40, 0xff, 0x50, 0xfa])
        var position = 0
        var status = try buffer.readUInt8(position)
        position += 1
        
        do {
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: position, withStatus: status)
            position += Int(bytesRead)
            
            XCTAssertEqual(
                event as! NoteOnEvent,
                NoteOnEvent(channel: 0, note: 64, velocity: 255))
            XCTAssertEqual(bytesRead, 2)
        }
        
        do {
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: position, withStatus: status)

            XCTAssertEqual(
                event as! NoteOnEvent,
                NoteOnEvent(channel: 0, note: 0x50, velocity: 0xfa))
            XCTAssertEqual(bytesRead, 2)
        }
        
        do {
            status = 0x95
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: 1, withStatus: status)
            XCTAssertEqual(
                event as! NoteOnEvent,
                NoteOnEvent(channel: 5, note: 64, velocity: 255))
            XCTAssertEqual(bytesRead, 2)

        }
    }
    
    func testReadNoteOffEvent() throws {
        let buffer = Data([0x80, 0x40, 0xff, 0x50, 0xfa])
        var position = 0
        var status = try buffer.readUInt8(position)
        position += 1
        
        do {
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: position, withStatus: status)
            position += Int(bytesRead)
            
            XCTAssertEqual(
                event as! NoteOffEvent,
                NoteOffEvent(channel: 0, note: 64, velocity: 255))
            XCTAssertEqual(bytesRead, 2)
        }
        
        do {
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: position, withStatus: status)

            XCTAssertEqual(
                event as! NoteOffEvent,
                NoteOffEvent(channel: 0, note: 0x50, velocity: 0xfa))
            XCTAssertEqual(bytesRead, 2)
        }
        
        do {
            status = 0x85
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: 1, withStatus: status)
            XCTAssertEqual(
                event as! NoteOffEvent,
                NoteOffEvent(channel: 5, note: 64, velocity: 255))
            XCTAssertEqual(bytesRead, 2)

        }
}
    
    func testPolyphonicAftertouchEvent() throws {
        let buffer = Data([0xA0, 0x40, 0xff, 0x50, 0xfa])
        var position = 0
        var status = try buffer.readUInt8(position)
        position += 1
        
        do {
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: position, withStatus: status)
            position += Int(bytesRead)
            
            XCTAssertEqual(
                event as! PolyphonicAftertouchEvent,
                PolyphonicAftertouchEvent(channel: 0, note: 64, pressure: 255))
            XCTAssertEqual(bytesRead, 2)
        }
        
        do {
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: position, withStatus: status)
            
            XCTAssertEqual(
                event as! PolyphonicAftertouchEvent,
                PolyphonicAftertouchEvent(channel: 0, note: 0x50, pressure: 0xfa))
            XCTAssertEqual(bytesRead, 2)
        }
        
        do {
            status = 0xA5
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: 1, withStatus: status)
            XCTAssertEqual(
                event as! PolyphonicAftertouchEvent,
                PolyphonicAftertouchEvent(channel: 5, note: 64, pressure: 255))
            XCTAssertEqual(bytesRead, 2)
        }
    }
    
    func testProgramChangeEvent() throws {
        let buffer = Data([0xc0, 0xff, 0xfa])
        var position = 0
        var status = try buffer.readUInt8(position)
        position += 1
        
        do {
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: position, withStatus: status)
            position += Int(bytesRead)
            
            XCTAssertEqual(
                event as! ProgramChangeEvent,
                ProgramChangeEvent(channel: 0, program: 0xff))
            XCTAssertEqual(bytesRead, 1)
        }
        
        do {
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: position, withStatus: status)
            
            XCTAssertEqual(
                event as! ProgramChangeEvent,
                ProgramChangeEvent(channel: 0, program: 0xfa))
            XCTAssertEqual(bytesRead, 1)
        }
        
        do {
            status = 0xc5
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: 1, withStatus: status)
            XCTAssertEqual(
                event as! ProgramChangeEvent,
                ProgramChangeEvent(channel: 5, program: 255))
            XCTAssertEqual(bytesRead, 1)
        }
    }
    
    func testChannelAftertouchEvent() throws {
        let buffer = Data([0xd0, 0xff, 0xfa])
        var position = 0
        var status = try buffer.readUInt8(position)
        position += 1
        
        do {
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: position, withStatus: status)
            position += Int(bytesRead)
            
            XCTAssertEqual(
                event as! ChannelAftertouchEvent,
                ChannelAftertouchEvent(channel: 0, pressure: 0xff))
            XCTAssertEqual(bytesRead, 1)
        }
        
        do {
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: position, withStatus: status)
            
            XCTAssertEqual(
                event as! ChannelAftertouchEvent,
                ChannelAftertouchEvent(channel: 0, pressure: 0xfa))
            XCTAssertEqual(bytesRead, 1)
        }
        
        do {
            status = 0xd5
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: 1, withStatus: status)
            XCTAssertEqual(
                event as! ChannelAftertouchEvent,
                ChannelAftertouchEvent(channel: 5, pressure: 255))
            XCTAssertEqual(bytesRead, 1)
        }
    }
    
    func testPitchBendEvent() throws {
        let buffer = Data([0xe0, 0x7f, 0x7f, 0, 0, 0, 0x40])
        var position = 0
        var status = try buffer.readUInt8(position)
        position += 1
        
        do {
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: position, withStatus: status)
            position += Int(bytesRead)
            
            XCTAssertEqual(
                event as! PitchBendEvent,
                PitchBendEvent(channel: 0, bend: 8191))
            XCTAssertEqual(bytesRead, 2)
        }
        
        do {
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: position, withStatus: status)
            position += Int(bytesRead)

            XCTAssertEqual(
                event as! PitchBendEvent,
                PitchBendEvent(channel: 0, bend: -8192))
            XCTAssertEqual(bytesRead, 2)
        }
        
        do {
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: position, withStatus: status)

            XCTAssertEqual(
                event as! PitchBendEvent,
                PitchBendEvent(channel: 0, bend: 0))
            XCTAssertEqual(bytesRead, 2)

        }
        
        do {
            status = 0xe5
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: 1, withStatus: status)
            XCTAssertEqual(
                event as! PitchBendEvent,
                PitchBendEvent(channel: 5, bend: 8191))
            XCTAssertEqual(bytesRead, 2)
        }
    }
    
    func testMTCQuarterFrameEvent() throws {
        let buffer = Data([0xf1, 0x0f, 0x11, 0x2f, 0x33, 0x4f, 0x53, 0x6f, 0x77])
        var position = 0
        let status = try buffer.readUInt8(position)
        position += 1
        
        do {
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: position, withStatus: status)
            position += Int(bytesRead)
            
            XCTAssertEqual(
                event as! MTCQuarterFrameEvent,
                MTCQuarterFrameEvent(part: 0, value: 15))
            XCTAssertEqual(bytesRead, 1)
        }
        
        do {
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: position, withStatus: status)
            position += Int(bytesRead)
            
            XCTAssertEqual(
                event as! MTCQuarterFrameEvent,
                MTCQuarterFrameEvent(part: 1, value: 1))
            XCTAssertEqual(bytesRead, 1)
        }
        
        do {
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: position, withStatus: status)
            position += Int(bytesRead)
            
            XCTAssertEqual(
                event as! MTCQuarterFrameEvent,
                MTCQuarterFrameEvent(part: 2, value: 15))
            XCTAssertEqual(bytesRead, 1)
        }
        
        do {
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: position, withStatus: status)
            position += Int(bytesRead)
            
            XCTAssertEqual(
                event as! MTCQuarterFrameEvent,
                MTCQuarterFrameEvent(part: 3, value: 3))
            XCTAssertEqual(bytesRead, 1)
        }
        
        do {
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: position, withStatus: status)
            position += Int(bytesRead)
            
            XCTAssertEqual(
                event as! MTCQuarterFrameEvent,
                MTCQuarterFrameEvent(part: 4, value: 15))
            XCTAssertEqual(bytesRead, 1)
        }
        
        do {
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: position, withStatus: status)
            position += Int(bytesRead)
            
            XCTAssertEqual(
                event as! MTCQuarterFrameEvent,
                MTCQuarterFrameEvent(part: 5, value: 3))
            XCTAssertEqual(bytesRead, 1)
        }

        do {
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: position, withStatus: status)
            position += Int(bytesRead)
            
            XCTAssertEqual(
                event as! MTCQuarterFrameEvent,
                MTCQuarterFrameEvent(part: 6, value: 15))
            XCTAssertEqual(bytesRead, 1)
        }
        
        do {
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: position, withStatus: status)
            position += Int(bytesRead)
            
            XCTAssertEqual(
                event as! MTCQuarterFrameEvent,
                MTCQuarterFrameEvent(part: 7, value: 7))
            XCTAssertEqual(bytesRead, 1)
        }
    }
    
    func testSongPositionEvent() throws {
        let buffer = Data([0xf2, 0x7f, 0x40, 0x40, 0x7f])
        var position = 0
        let status = try buffer.readUInt8(position)
        position += 1
        
        do {
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: position, withStatus: status)
            position += Int(bytesRead)
            
            XCTAssertEqual(
                event as! SongPositionChangeEvent,
                SongPositionChangeEvent(position: 8319)
            )
            XCTAssertEqual(bytesRead, 2)
        }
        
        do {
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: position, withStatus: status)
            position += Int(bytesRead)
            
            XCTAssertEqual(
                event as! SongPositionChangeEvent,
                SongPositionChangeEvent(position: 16320)
            )
            XCTAssertEqual(bytesRead, 2)
        }
    }
    
    func testSongSelectionEvent() throws {
        let buffer = Data([0xf3, 0x7f, 0x40])
        var position = 0
        let status = try buffer.readUInt8(position)
        position += 1
        
        do {
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: position, withStatus: status)
            position += Int(bytesRead)
            
            XCTAssertEqual(
                event as! SongSelectEvent,
                SongSelectEvent(song: 127)
            )
            XCTAssertEqual(bytesRead, 1)
        }
        
        do {
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: position, withStatus: status)
            position += Int(bytesRead)
            
            XCTAssertEqual(
                event as! SongSelectEvent,
                SongSelectEvent(song: 64)
            )
            XCTAssertEqual(bytesRead, 1)
        }
    }
    
    func testDataLessEvents() throws {
        let buffer = Data([0xf6, 0xf8, 0xfa, 0xfb, 0xfc, 0xfe, 0xff])
        var position = 0
        var status = try buffer.readUInt8(position)
        position += 1
        
        do {
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: position, withStatus: status)
            status = try buffer.readUInt8(position)
            position += 1
            
            XCTAssertEqual(
                event as! TuneRequestEvent,
                TuneRequestEvent()
            )
            XCTAssertEqual(bytesRead, 0)
        }
        
        do {
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: position, withStatus: status)
            status = try buffer.readUInt8(position)
            position += 1
            
            XCTAssertEqual(
                event as! TimingClockEvent,
                TimingClockEvent()
            )
            XCTAssertEqual(bytesRead, 0)
        }
        
        do {
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: position, withStatus: status)
            status = try buffer.readUInt8(position)
            position += 1
            
            XCTAssertEqual(
                event as! StartEvent,
                StartEvent()
            )
            XCTAssertEqual(bytesRead, 0)
        }
        
        do {
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: position, withStatus: status)
            status = try buffer.readUInt8(position)
            position += 1
            
            XCTAssertEqual(
                event as! ContinueEvent,
                ContinueEvent()
            )
            XCTAssertEqual(bytesRead, 0)
        }
        
        do {
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: position, withStatus: status)
            status = try buffer.readUInt8(position)
            position += 1
            
            XCTAssertEqual(
                event as! StopEvent,
                StopEvent()
            )
            XCTAssertEqual(bytesRead, 0)
        }
        
        do {
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: position, withStatus: status)
            status = try buffer.readUInt8(position)
            position += 1
            
            XCTAssertEqual(
                event as! ActiveSensingEvent,
                ActiveSensingEvent()
            )
            XCTAssertEqual(bytesRead, 0)
        }
        
        do {
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: position, withStatus: status)
            
            XCTAssertEqual(
                event as! SystemResetEvent,
                SystemResetEvent()
            )
            XCTAssertEqual(bytesRead, 0)
        }
        
    }
}

