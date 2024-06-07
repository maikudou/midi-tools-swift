//
//  readHeader.swift
//
//
//  Created by Mikhail Labanov on 5/2/24.
//

import Foundation

public func readHeader(from buffer: Data) throws -> (bytesRead: UInt32, header: Header) {
    // MThd
    let FILE_HEADER = Data([0x4d, 0x54, 0x68, 0x64])
    
    func readHeaderLength(at position: Data.Index = 0) throws -> UInt32 {
        return try buffer.readUInt32BE(position)
    }
    
    func readFileType(at position: Data.Index = 0) throws -> UInt16 {
        return try buffer.readUInt16BE(position)
    }
    
    func readTracksCount(at position: Data.Index = 0) throws -> UInt16 {
        return try buffer.readUInt16BE(position)
    }
    
    func readDivision(at position: Data.Index = 0) throws -> Division {
        if (try buffer.readUInt8(position) & 0x80 != 0) {
            // time-code based
            return Division.timeCode(
                DivisionTimeCode(
                    fps: -(try buffer.readInt8(position)),
                    ticksPerFrame: try buffer.readUInt8(position + 1)
                )
            )
        } else {
            // metric
            return Division.metric(
                DivisionMetric(
                    ticksPerQuarterNote: try buffer.readUInt16BE(position)
                )
            )
        }
    }
    
    
    if (buffer.count < 4) {
        throw ParseError.outOfBounds
    }
    if (!buffer.subdata(in: Range<Data.Index>(0...3)).elementsEqual(FILE_HEADER)) {
        throw ParseError.invalidHeader
    }
    
    var bytesRead: UInt32 = 4
    
    let headerLength = try readHeaderLength(at: Data.Index(bytesRead))
    bytesRead += 4
    let fileType = try readFileType(at: Data.Index(bytesRead))
    bytesRead += 2
    let tracksCount = try readTracksCount(at: Data.Index(bytesRead))
    bytesRead += 2
    let division = try readDivision(at: Data.Index(bytesRead))
    bytesRead += 2
    
    var extraData: Data? = nil
    if (headerLength > 6) {
        extraData = buffer[bytesRead..<(bytesRead + headerLength - 6)]
    }
            
    // Skip any header fields we don't know about
    bytesRead += headerLength - 6
    
    if (fileType > 2) {
        throw ParseError.invalidFileType(fileType: fileType)
    }
    
    return (bytesRead,
        Header(
            type: fileType,
            tracksCount: tracksCount,
            division: division,
            extraData: extraData
        )
    )
}

