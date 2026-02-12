//
//  readMIDIFile.swift
//  MidiToolsSwift
//
//  Created by Mike Henkel on 2/7/26.
//

import Foundation

public func readMIDIFile(
    from buffer: Data,
) throws -> MIDIFile {
    let (bytesRead, header) = try readHeader(from: buffer)
    var tracks: [Track] = []
    var position = bytesRead
    
    for trackNumber in 0..<header.tracksCount {
        let (bytesRead, track) = try readTrack(
            number: trackNumber,
            from: buffer,
            at: Int(position)
        )
        tracks.append(track)
        position += bytesRead
    }
    
    return MIDIFile(header: header, tracks: tracks)
}
