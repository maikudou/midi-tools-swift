//
//  readEvent.swift
//
//
//  Created by Mikhail Labanov on 5/10/24.
//

import Foundation

func readEvent(
    from buffer: Data,
    at position: Data.Index,
    withRunningStatus runningStatus: inout UInt8?
) throws -> (bytesRead: Int, deltaTime: UInt32, event: any Event) {
    
    func readDeltaTime(
        at position: Data.Index
    ) throws -> (bytesRead: UInt32, deltaTime: UInt32) {
        let (bytesRead, deltaTime) = try buffer.readVariableQuantity(position)
        return (bytesRead, deltaTime)
    }

    var bytesRead = 0
    
    let ( deltaTimeBytesRead, deltaTime ) = try readDeltaTime(at: position)

    bytesRead += Int(deltaTimeBytesRead)
    
    let firstByte = try buffer.readUInt8(position + bytesRead)
    bytesRead += 1
    
    switch (firstByte) {
    case 0xff:
        let ( metaEventBytesRead, metaEvent ) = try readMetaEvent(
            from: buffer,
            at: position + bytesRead
        )
        bytesRead += Int(metaEventBytesRead)
        runningStatus = nil
        return (bytesRead, deltaTime, metaEvent)
    case 0xf0, 0xf7:
        let ( sysexEventBytesRead, sysexEvent ) = try readSysExEvent(
            from: buffer, at: position + bytesRead, withStatus: firstByte
        )
        bytesRead += Int(sysexEventBytesRead)
        runningStatus = nil
        switch (sysexEvent) {
        case .initial(let event):
            return (bytesRead, deltaTime, event)
        case .continued(let event):
            return (bytesRead, deltaTime, event)
        }
    default:
        // If 8th bit of a byte is not zero, it's status.
        // otherwise, its data
        if (firstByte >> 7 != 0) {
            runningStatus = firstByte
        } else {
            bytesRead -= 1
        }
        let ( midiEventBytesRead, event ) = try readChannelEvent(
            from: buffer, at: position + bytesRead, withStatus: runningStatus!
        )
        bytesRead += Int(midiEventBytesRead)
        return (bytesRead, deltaTime, event)
    }
}
