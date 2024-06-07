//
//  readMetaEvent.swift
//
//
//  Created by Mike Henkel on 5/6/24.
//

import Foundation

func readMetaEvent(
    from buffer: Data,
    at position: Data.Index
) throws -> (bytesRead: UInt32, event: any MetaEvent) {
    func readMetaEventType(
        at position: Data.Index
    ) throws -> (bytesRead: UInt32, eventType: UInt8) {
        
        return (1,
                try buffer.readUInt8(position)
        )
    }
    
    /**
     * Sequence number meta-event always has two-byte data
     */
    func readSequenceNumber(
        at position: Data.Index
    ) throws -> (bytesRead: UInt32, sequenceNumber: UInt16) {
        let length = try buffer.readUInt8(position)
        try checkLength(actual: Int(length), expected: 2)
        
        return (3,
                try buffer.readUInt16BE(position + 1)
        )
    }
    
    /**
     * Channel prefix meta event always has lenght of 1 byte
     */
    func readChannelPrefix(
        at position: Data.Index
    ) throws -> (bytesRead: UInt32, channelPrefix: UInt8) {
        let length = try buffer.readUInt8(position)
        try checkLength(actual: Int(length), expected: 1)
        let channel = try buffer.readUInt8(position + 1)
        
        return (2,
                channel
        )
    }
    
    /**
     * Port prefix meta event always has lenght of 1 byte
     */
    func readPortPrefix(
        at position: Data.Index
    ) throws -> (bytesRead: UInt32, portPrefix: UInt8) {
        let length = try buffer.readUInt8(position)
        try checkLength(actual: Int(length), expected: 1)
        let port = try buffer.readUInt8(position + 1)
        
        return (2,
                port
        )
    }
    
    /**
     * End of track meta-event always has 0 as its only data byte
     */
    func readEndOfTrack(
        at position: Data.Index
    ) throws -> (bytesRead: UInt32, zero: UInt8) {
        let result = try buffer.readUInt8(position)
        try checkLength(actual: Int(result), expected: 0)
        
        return (1, 0)
    }
    
    func readTempo(
        at position: Data.Index
    ) throws -> (bytesRead: UInt32, tempo: Tempo) {
        let length = try buffer.readUInt8(position)
        try checkLength(actual: Int(length), expected: 3)
        
        let microsecondsForQuarterNote = try buffer.readUInt32BE(position) & 0xFF_FF_FF
        
        return (4,
                Tempo(
                    microsecondsPerQuarterNote: microsecondsForQuarterNote,
                    beatsPerMinute: UInt16(60 / (Float(microsecondsForQuarterNote) / 1_000_000)))
        )
    }
    
    func readSFMPTEOffset(
        at position: Data.Index
    ) throws -> (bytesRead: UInt32, offset: SFMPTEOffset) {
        let length = try buffer.readUInt8(position)
        try checkLength(actual: Int(length), expected: 5)
        
        return (6,
                SFMPTEOffset(
                    hours: try buffer.readUInt8(position + 1),
                    minutes: try buffer.readUInt8(position + 2),
                    seconds: try buffer.readUInt8(position + 3),
                    frames: try buffer.readUInt8(position + 4),
                    fractionalFrames: try buffer.readUInt8(position + 5)
                )
        )
    }
    
    func readTimeSignature(
        at position: Data.Index
    ) throws -> (bytesRead: UInt32, timeSignature: TimeSignature) {
        let length = try buffer.readUInt8(position)
        try checkLength(actual: Int(length), expected: 4)
        let denominator = try pow(2, Int(buffer.readUInt8(position + 2)))
        
        return (5,
                TimeSignature(
                    numerator: try buffer.readUInt8(position + 1),
                    denominator: UInt8(truncating: NSDecimalNumber(decimal: denominator)),
                    clocksPerClick: try buffer.readUInt8(position + 3),
                    bb: try buffer.readUInt8(position + 4)
                )
        )
    }
    
    func readKeySignature(
        at position: Data.Index
    ) throws -> (bytesRead: UInt32, keySignature: KeySignature) {
        let length = try buffer.readUInt8(position)
        try checkLength(actual: Int(length), expected: 2)
        let sharpOrFlats = try buffer.readInt8(position + 1)
        let major = try buffer.readUInt8(position + 2)
        
        return (3,
                KeySignature(
                    flats: sharpOrFlats < 0 ? UInt8(-sharpOrFlats) : 0,
                    sharps: sharpOrFlats > 0 ? UInt8(sharpOrFlats) : 0,
                    major: major == 0 ? true : false
                )
        )
    }
    
    func readSequencerSpecificData(
        at position: Data.Index
    ) throws -> (bytesRead: UInt32, data: SequencerSpecificData) {
        let ssData = try buffer.readVariableLengthData(position)
        let manufacturerIdLength = ssData.data[0] == 0 ? 3 : 1
        let manufacturerId = (manufacturerIdLength == 3
                              ? ssData.data.subdata(in: Range(0...2))
                              : ssData.data.subdata(in: Range(0...0)))
            .map {String(format: "%02hhx", $0)}.joined()
        
        return (ssData.bytesRead,
                ssData.data.count > manufacturerIdLength
                ?  SequencerSpecificData(
                    manufacturerId: manufacturerId,
                    data: ssData.data.suffix(from: manufacturerIdLength)
                )
                : SequencerSpecificData(manufacturerId: manufacturerId)
        )
    }
    
    let readResult = try readMetaEventType(at: position)
    let eventType = readResult.eventType
    let eventTypeBytesRead = readResult.bytesRead
    
    var bytesRead = eventTypeBytesRead
    
    switch (eventType) {
    case 0x00:
        let result = try readSequenceNumber(at: position + Int(bytesRead))
        bytesRead += result.bytesRead
        
        return (
            bytesRead: bytesRead,
            SequenceNumberMetaEvent(sequenceNumber: result.sequenceNumber)
        )
    case 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09:
        let result = try buffer.readVariableLengthData(position + Int(bytesRead))
        let textData = String(data: result.data, encoding: String.Encoding.isoLatin1)!
        bytesRead += result.bytesRead
        
        switch eventType {
        case 0x01:
            return (bytesRead, TextMetaEvent(text: textData))
        case 0x02:
            return (bytesRead, CopyrightNoticeMetaEvent(text: textData))
        case 0x03:
            return (bytesRead, SequenceOrTrackNameMetaEvent(text: textData))
        case 0x04:
            return (bytesRead, InstrumentNameMetaEvent(text: textData))
        case 0x05:
            return (bytesRead, LyricMetaEvent(text: textData))
        case 0x06:
            return (bytesRead, MarkerMetaEvent(text: textData))
        case 0x07:
            return (bytesRead, CuePointMetaEvent(text: textData))
        case 0x08:
            return (bytesRead, ProgramNameMetaEvent(text: textData))
        default:
            return (bytesRead, DeviceNameMetaEvent(text: textData))
        }
    case 0x20:
        let result = try readChannelPrefix(at: position + Int(bytesRead))
        bytesRead += result.bytesRead
        
        return (bytesRead,
                ChannelPrefixMetaEvent(channelPrefix: result.channelPrefix)
        )
    
    case 0x21:
        let result = try readPortPrefix(at: position + Int(bytesRead))
        bytesRead += result.bytesRead
        
        return (bytesRead,
                PortPrefixMetaEvent(portPrefix: result.portPrefix)
        )
        
    case 0x2f:
        let result = try readEndOfTrack(at: position + Int(bytesRead))
        bytesRead += result.bytesRead
        
        return (bytesRead, EndOfTrackMetaEvent())
    case 0x51:
        let result = try readTempo(at: position + Int(bytesRead))
        bytesRead += result.bytesRead
        
        return (bytesRead,
                SetTempoMetaEvent(tempo: result.tempo)
        )
    case 0x54:
        let result = try readSFMPTEOffset(at: position + Int(bytesRead))
        bytesRead += result.bytesRead
        
        return (bytesRead,
                SFMPTEOffsetMetaEvent(offset: result.offset)
        )
    case 0x58:
        let result = try readTimeSignature(at: position + Int(bytesRead))
        bytesRead += result.bytesRead
        
        return (bytesRead,
                TimeSignatureMetaEvent(timeSignature: result.timeSignature)
        )
    case 0x59:
        let result = try readKeySignature(at: position + Int(bytesRead))
        bytesRead += result.bytesRead
        
        return (bytesRead,
                KeySignatureMetaEvent(keySignature: result.keySignature)
        )
    case 0x7F:
        let result = try readSequencerSpecificData(at: position + Int(bytesRead))
        bytesRead += result.bytesRead
        
        return (bytesRead,
                SequencerSpecificMetaEvent(
                    manufacturerId: result.data.manufacturerId,
                    data: result.data.data
                )
        )
    default:
        let result = try buffer.readVariableLengthData(position + Int(bytesRead))
        bytesRead += result.bytesRead
        
        return (bytesRead,
                UnknownMetaEvent(type: eventType, data: result.data)
        )
    }
}
