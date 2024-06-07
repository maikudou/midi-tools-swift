//
//  readTrack.swift
//
//
//  Created by Mike Henkel on 5/12/24.
//

import Foundation

public func readTrack(
    number: UInt16,
    from buffer: Data,
    at position: Data.Index
) throws -> (bytesRead: UInt32, track: Track) {
    // MTrk
    let TRACK_HEADER = Data([0x4d, 0x54, 0x72, 0x6b])
    
    func readTrackLength(at position: Data.Index = 0) throws -> (bytesRead: UInt32, UInt32) {
        return try (4, buffer.readUInt32BE(position))
    }
    
    var track = Track(number: number, events: [])
    
    if (buffer.count < 4) {
        throw ParseError.outOfBounds
    }
    if (!buffer.subdata(in: Range<Data.Index>(position...position + 3)).elementsEqual(TRACK_HEADER)) {
        throw ParseError.invalidTrackPrefix
    }
    
    var totalBytesRead = 4
    
    let (trackLengthBytesRead, trackLength) = try readTrackLength(at: position + totalBytesRead)
    totalBytesRead += Int(trackLengthBytesRead)
    
    var bytesLeft = trackLength
    var runningStatus: UInt8? = nil
    
    while (bytesLeft > 0) {
        let (bytesRead, deltaTime, event) = try readEvent(
            from: buffer,
            at: position + totalBytesRead,
            withRunningStatus: &runningStatus
        )
        track.events.append((deltaTime, event))
        bytesLeft -= UInt32(bytesRead)
        totalBytesRead += Int(bytesRead)
    }
    
    return (UInt32(totalBytesRead), track)
}
