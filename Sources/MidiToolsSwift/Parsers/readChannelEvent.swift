//
//  readChannelEvent.swift
//
//
//  Created by Mike Henkel on 5/9/24.
//

import Foundation

func readChannelEvent(
    from buffer: Data,
    at position: Data.Index,
    withStatus status: UInt8
) throws -> (bytesRead: UInt32, event: any Event) {
    
    func readNoteEvent(
        from buffer: Data,
        at position: Data.Index,
        withStatus status: UInt8
    ) throws -> (bytesRead: UInt32, event: any NoteEvent) {
        let note = try buffer.readUInt8(position)
        let velocity = try buffer.readUInt8(position + 1)
        let isNoteOn = status & 0xF0 == 0x90
        let channel = status & 0x0F
        
        return (2,
            isNoteOn
            ? NoteOnEvent(channel: channel, note: note, velocity: velocity)
            : NoteOffEvent(channel: channel, note: note, velocity: velocity)
        )
    }
    
    func readPolyphonicAftertouchEvent(
        from buffer: Data,
        at position: Data.Index,
        withStatus status: UInt8
    ) throws -> (bytesRead: UInt32, event: PolyphonicAftertouchEvent) {
        let note = try buffer.readUInt8(position)
        let pressure = try buffer.readUInt8(position + 1)
        let channel = status & 0x0F
        
        return (2,
            PolyphonicAftertouchEvent(channel: channel, note: note, pressure: pressure)
        )
    }
    
    func readChannelAftertouchEvent(
        from buffer: Data,
        at position: Data.Index,
        withStatus status: UInt8
    ) throws -> (bytesRead: UInt32, event: ChannelAftertouchEvent) {
        let pressure = try buffer.readUInt8(position)
        let channel = status & 0x0F
        
        return (1,
            ChannelAftertouchEvent(channel: channel, pressure: pressure)
        )
    }
    
    /**
     * From the Spec:
     *
     * Pitch Bender messages are always sent with 14 bit resolution (2 bytes).
     * In contrast to other MIDI functions, which may send either the LSB or MSB,
     * the Pitch Bender message is always transmitted with both data bytes[, LSB first].
     * This takes into account human hearing which is particularly sensitive to pitch
     * changes. [...] The maximum negative swing is achieved with data byte values
     * of 00, 00. The center (no effect) position is achieved with data byte values
     * of 00, 64 (00H, 40H). The maximum positive swing is achieved with data byte
     * values of 127, 127 (7FH, 7FH).
     */
    func readPitchBendChangeEvent(
        from buffer: Data,
        at position: Data.Index,
        withStatus status: UInt8
    ) throws -> (bytesRead: UInt32, event: PitchBendEvent) {
        let bend = try buffer.read7bitWordLE(position)
        let channel = status & 0x0F
        
        return (2,
            PitchBendEvent(channel: channel, bend: Int16(bend) - 0x2000)
        )
    }
    
    func readMTCQuarterFrameEvent(
        from buffer: Data,
        at position: Data.Index
    ) throws -> (bytesRead: UInt32, event: MTCQuarterFrameEvent) {
        let byte = try buffer.readUInt8(position)
        
        return (1,
            MTCQuarterFrameEvent(
                part: byte >> 4,
                value: byte & 0x0F
            )
        )
    }
    
    /**
     * Song position also has LSB and MSB each time, like pitch bend
     */
    func readSongPositionChangeEvent(
        from buffer: Data,
        at position: Data.Index
    ) throws -> (bytesRead: UInt32, event: SongPositionChangeEvent) {
        let position = try buffer.read7bitWordLE(position)
        
        return (2,
            SongPositionChangeEvent(position: position)
        )
    }
    
    func readSongSelectEvent(
        from buffer: Data,
        at position: Data.Index
    ) throws -> (bytesRead: UInt32, event: SongSelectEvent) {
        let song = try buffer.readUInt8(position)
        
        return (1,
            SongSelectEvent(song: song)
        )
    }
    
    func readControlEvent(
        from buffer: Data,
        at position: Data.Index,
        withStatus status: UInt8
    ) throws -> (bytesRead: UInt32, event: ControlEvent) {
        let channel = status & 0x0F
        let eventType = try buffer.readUInt8(position)
        
        switch (eventType) {
        case
            0x0, 0x1, 0x2, 0x4, 0x5, 0x6, 0x7, 0x8,
            0xa, 0xb, 0xc, 0xd, 0x10, 0x11, 0x12,0x13:
            let value = try buffer.readUInt8(position + 1)
            
            return (2,
                ControlEvent(
                    channel: channel,
                    control: eventType,
                    value: value,
                    kind: .MSB
                )
            )
            
        case
            0x20, 0x21, 0x22, 0x24, 0x25, 0x26, 0x27, 0x28,
            0x2a, 0x2b, 0x2c, 0x2d, 0x30, 0x31, 0x32, 0x33:
            let value = try buffer.readUInt8(position+1)
            
            return (2,
                ControlEvent(
                    channel: channel,
                    control: eventType,
                    value: value,
                    kind: .LSB
                )
            )
            
        case 0x3, 0x9, 0xe, 0xf, 0x14, 0x15, 0x16, 0x17,
            0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f:
            let value = try buffer.readUInt8(position + 1)
            
            return (2,
                ControlEvent(
                    channel: channel,
                    control: eventType,
                    value: value,
                    kind: .MSB
                )
            )
            
        case 0x23, 0x29, 0x2e, 0x2f, 0x34, 0x35, 0x36, 0x37,
            0x38, 0x39, 0x3a, 0x3b, 0x3c, 0x3d, 0x3e, 0x3f:
            let value = try buffer.readUInt8(position+1)
            
            return (2,
                ControlEvent(
                    channel: channel,
                    control: eventType,
                    value: value,
                    kind: .LSB
                )
            )
            
        case 0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x5b, 0x5c,
            0x5d, 0x5e, 0x5f, 0x62, 0x63, 0x64, 0x65, 0x78,
            0x79, 0x7a, 0x7b, 0x7c, 0x7d, 0x7e, 0x7f:
            let value = try buffer.readUInt8(position+1)
            
            return (2,
                ControlEvent(
                    channel: channel,
                    control: eventType,
                    value: value,
                    kind: .SingleByte
                )
            )
        default:
            return (2,
                ControlEvent(
                    channel: channel,
                    control: eventType,
                    value: nil,
                    kind: .Empty
                )
            )
        }
    }
    
    func readProgramChangeEvent(
        from buffer: Data,
        at position: Data.Index,
        withStatus status: UInt8
    ) throws -> (bytesRead: UInt32, event: ProgramChangeEvent) {
        let channel = status & 0x0F
        let program = try buffer.readUInt8(position)
        
        return (1,
            ProgramChangeEvent(channel: channel, program: program)
        )
    }
    
    let statusMSN = status >> 4
    let statusLSN = status & 0xf
    
    switch (statusMSN) {
    case 0x8, 0x9:
        let (bytesRead, event) = try readNoteEvent(from: buffer, at: position, withStatus: status)
        return (bytesRead, event as! (any Event))

    case 0xa:
        return try readPolyphonicAftertouchEvent(from: buffer, at: position, withStatus: status)
        
    case 0xb:
        return try readControlEvent(from: buffer, at: position, withStatus: status)
        
    case 0xc:
        return try readProgramChangeEvent(from: buffer, at: position, withStatus: status)
        
    case 0xd:
        return try readChannelAftertouchEvent(from: buffer, at: position, withStatus: status)
        
    case 0xe:
        return try readPitchBendChangeEvent(from: buffer, at: position, withStatus: status)
        
    default:
        switch (statusLSN) {
        case 0x1:
            return try readMTCQuarterFrameEvent(from: buffer, at: position)
            
        case 0x2:
            return try readSongPositionChangeEvent(from: buffer, at: position)
            
        case 0x3:
            return try readSongSelectEvent(from: buffer, at: position)
            
        case 0x6:
            return (0, TuneRequestEvent())
            
        case 0x8:
            return (0, TimingClockEvent())

        case 0xa:
            return (0, StartEvent())

        case 0xb:
            return (0, ContinueEvent())

        case 0xc:
            return (0, StopEvent())

        case 0xe:
            return (0, ActiveSensingEvent())

        default:
            return (0, SystemResetEvent())
        }
    }
}
