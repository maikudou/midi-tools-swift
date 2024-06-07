//
//  WriteChannelEventTests.swift
//
//
//  Created by Mikhail Labanov on 6/5/24.
//

import XCTest
@testable import MidiToolsSwift

final class WriteChannelEventTests: XCTestCase {
    
    func testNoteOnEvent() throws {
        let buffer = Data([0x90, 0x40, 0xff])
        let status = try buffer.readUInt8(0)
        
        let (_, event) = try readChannelEvent(from: buffer, at: 1, withStatus: status)
        XCTAssertEqual(event.rawData, buffer)
    }
    
    func testNoteOffEvent() throws {
        let buffer = Data([0x80, 0x40, 0xff])
        let status = try buffer.readUInt8(0)
        
        let (_, event) = try readChannelEvent(from: buffer, at: 1, withStatus: status)
        XCTAssertEqual(event.rawData, buffer)
    }
    
    func testPolyphonicAftertouchEvent() throws {
        let buffer = Data([0xA0, 0x40, 0xff])
        let status = try buffer.readUInt8(0)
        
        let (_, event) = try readChannelEvent(from: buffer, at: 1, withStatus: status)
        XCTAssertEqual(event.rawData, buffer)
    }
    
    func testProgramChangeEvent() throws {
        let buffer = Data([0xc0, 0xff])
        let status = try buffer.readUInt8(0)
        
        let (_, event) = try readChannelEvent(from: buffer, at: 1, withStatus: status)
        XCTAssertEqual(event.rawData, buffer)
    }
    
    func testChannelAftertouchEvent() throws {
        let buffer = Data([0xd0, 0xff])
        let status = try buffer.readUInt8(0)
        
        let (_, event) = try readChannelEvent(from: buffer, at: 1, withStatus: status)
        XCTAssertEqual(event.rawData, buffer)
    }
    
    func testPitchBendEvent() throws {
        let buffer = Data([0xe0, 0x7f, 0x7f, 0, 0, 0, 0x40])
        var position = 0
        var status = try buffer.readUInt8(position)
        position += 1
        
        do {
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: position, withStatus: status)
            var expectedData = Data([status])
            expectedData.append(buffer[position..<(position+Int(bytesRead))])
            XCTAssertEqual(event.rawData, expectedData)
            position += Int(bytesRead)
        }
        
        do {
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: position, withStatus: status)
            var expectedData = Data([status])
            expectedData.append(buffer[position..<(position+Int(bytesRead))])
            XCTAssertEqual(event.rawData, expectedData)
            position += Int(bytesRead)
        }
        
        do {
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: position, withStatus: status)
            
            var expectedData = Data([status])
            expectedData.append(buffer[position..<(position+Int(bytesRead))])
            XCTAssertEqual(event.rawData, expectedData)
        }
        
        do {
            status = 0xe5
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: 1, withStatus: status)
            
            var expectedData = Data([status])
            expectedData.append(buffer[1..<(1+Int(bytesRead))])
            XCTAssertEqual(event.rawData, expectedData)
        }
    }
    
    func testMTCQuarterFrameEvent() throws {
        let buffer = Data([0xf1, 0x0f, 0x11, 0x2f, 0x33, 0x4f, 0x53, 0x6f, 0x77])
        var position = 0
        let status = try buffer.readUInt8(position)
        position += 1
        
        do {
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: position, withStatus: status)
            var expectedData = Data([status])
            expectedData.append(buffer[position..<(position+Int(bytesRead))])
            XCTAssertEqual(event.rawData, expectedData)
            position += Int(bytesRead)
        }
        
        do {
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: position, withStatus: status)
            var expectedData = Data([status])
            expectedData.append(buffer[position..<(position+Int(bytesRead))])
            XCTAssertEqual(event.rawData, expectedData)
            position += Int(bytesRead)
        }
        
        do {
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: position, withStatus: status)
            var expectedData = Data([status])
            expectedData.append(buffer[position..<(position+Int(bytesRead))])
            XCTAssertEqual(event.rawData, expectedData)
            position += Int(bytesRead)
        }
        
        do {
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: position, withStatus: status)
            var expectedData = Data([status])
            expectedData.append(buffer[position..<(position+Int(bytesRead))])
            XCTAssertEqual(event.rawData, expectedData)
            position += Int(bytesRead)
        }
        
        do {
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: position, withStatus: status)
            var expectedData = Data([status])
            expectedData.append(buffer[position..<(position+Int(bytesRead))])
            XCTAssertEqual(event.rawData, expectedData)
            position += Int(bytesRead)
        }
        
        do {
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: position, withStatus: status)
            var expectedData = Data([status])
            expectedData.append(buffer[position..<(position+Int(bytesRead))])
            XCTAssertEqual(event.rawData, expectedData)
            position += Int(bytesRead)
        }
        
        do {
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: position, withStatus: status)
            var expectedData = Data([status])
            expectedData.append(buffer[position..<(position+Int(bytesRead))])
            XCTAssertEqual(event.rawData, expectedData)
            position += Int(bytesRead)
        }
        
        do {
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: position, withStatus: status)
            var expectedData = Data([status])
            expectedData.append(buffer[position..<(position+Int(bytesRead))])
            XCTAssertEqual(event.rawData, expectedData)
            position += Int(bytesRead)
        }
    }
    
    func testSongPositionEvent() throws {
        let buffer = Data([0xf2, 0x7f, 0x40, 0x40, 0x7f])
        var position = 0
        let status = try buffer.readUInt8(position)
        position += 1
        
        do {
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: position, withStatus: status)
            var expectedData = Data([status])
            expectedData.append(buffer[position..<(position+Int(bytesRead))])
            XCTAssertEqual(event.rawData, expectedData)
            position += Int(bytesRead)
        }
        
        do {
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: position, withStatus: status)
            var expectedData = Data([status])
            expectedData.append(buffer[position..<(position+Int(bytesRead))])
            XCTAssertEqual(event.rawData, expectedData)
            position += Int(bytesRead)
        }
    }
    
    func testSongSelectionEvent() throws {
        let buffer = Data([0xf3, 0x7f, 0x40])
        var position = 0
        let status = try buffer.readUInt8(position)
        position += 1
        
        do {
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: position, withStatus: status)
            var expectedData = Data([status])
            expectedData.append(buffer[position..<(position+Int(bytesRead))])
            XCTAssertEqual(event.rawData, expectedData)
            position += Int(bytesRead)
        }
        
        do {
            let (bytesRead, event) = try readChannelEvent(from: buffer, at: position, withStatus: status)
            var expectedData = Data([status])
            expectedData.append(buffer[position..<(position+Int(bytesRead))])
            XCTAssertEqual(event.rawData, expectedData)
            position += Int(bytesRead)
        }
    }
    
    func testDataLessEvents() throws {
        let buffer = Data([0xf6, 0xf8, 0xfa, 0xfb, 0xfc, 0xfe, 0xff])
        
        for position in 0..<buffer.count {
            let status = try buffer.readUInt8(position)
            let (_, event) = try readChannelEvent(from: buffer, at: position + 1, withStatus: status)
            XCTAssertEqual(event.rawData, Data([status]))
        }
    }
}
