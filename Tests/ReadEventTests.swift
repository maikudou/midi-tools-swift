//
//  ReadEventTests.swift
//  
//
//  Created by Mikhail Labanov on 5/10/24.
//

import XCTest
@testable import MidiToolsSwift

final class ReadEventTests: XCTestCase {

    func testReadMetaEvent() throws {
        let buffer = Data([0x00, 0xff, 0x2f, 0x00, 0x10, 0xff, 0x00, 0x02, 0x00,0x01])
        var runningStatus: UInt8? = nil
        
        do {
            let ( bytesRead, deltaTime, event ) = try readEvent(
                from: buffer, at: 0, withRunningStatus: &runningStatus)
            
            XCTAssert(bytesRead == 4)
            XCTAssert(deltaTime == 0)
            XCTAssertEqual(event as! EndOfTrackMetaEvent, EndOfTrackMetaEvent())
        }
        
        do {
            let ( bytesRead, deltaTime, event ) = try readEvent(
                from: buffer, at: 4, withRunningStatus: &runningStatus)
            
            XCTAssert(bytesRead == 6)
            XCTAssert(deltaTime == 0x10)
            XCTAssertEqual(
                event as! SequenceNumberMetaEvent,
                SequenceNumberMetaEvent(sequenceNumber: 1))
        }
    }
    
    func testReadSysexEvent() throws {
        let buffer = Data([0x00, 0xf0, 0x02, 0x45, 0xf3,
                           0x10, 0xf7, 0x03, 0x45, 0xf3, 0xdd])
        
        var runningStatus: UInt8? = nil
        
        do {
            let ( bytesRead, deltaTime, event ) = try readEvent(
                from: buffer, at: 0, withRunningStatus: &runningStatus)
            
            XCTAssert(bytesRead == 5)
            XCTAssert(deltaTime == 0)
            XCTAssertEqual(event as! SysExEventInitial, SysExEventInitial(buffer: Data([0x45, 0xf3])))
        }
        
        do {
            let ( bytesRead, deltaTime, event ) = try readEvent(
                from: buffer, at: 5, withRunningStatus: &runningStatus)
            
            XCTAssert(bytesRead == 6)
            XCTAssert(deltaTime == 0x10)
            XCTAssertEqual(
                event as! SysExEventContinued,
                SysExEventContinued(buffer: Data([0x45, 0xf3, 0xdd])))
        }
    }
    
    func testReadChannelEvent() throws {
        let buffer = Data([0x00, 0x90, 0x40, 0xff, 0x10, 0x50, 0xfa])
        
        var runningStatus: UInt8? = nil
        
        do {
            let ( bytesRead, deltaTime, event ) = try readEvent(
                from: buffer, at: 0, withRunningStatus: &runningStatus)
            
            XCTAssert(bytesRead == 4)
            XCTAssert(deltaTime == 0)
            XCTAssertEqual(event as! NoteOnEvent, NoteOnEvent(channel: 0, note: 0x40, velocity: 0xff))
        }
        
        do {
            let ( bytesRead, deltaTime, event ) = try readEvent(
                from: buffer, at: 4, withRunningStatus: &runningStatus)
            
            XCTAssert(bytesRead == 3)
            XCTAssert(deltaTime == 0x10)
            XCTAssertEqual(
                event as! NoteOnEvent,
                NoteOnEvent(channel: 0, note: 0x50, velocity: 0xfa))
        }
    }
}
