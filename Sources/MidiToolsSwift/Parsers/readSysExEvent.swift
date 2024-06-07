//
//  readSysExEvent.swift
//
//
//  Created by Mike Henkel on 5/6/24.
//

import Foundation

func readSysExEvent(from buffer: Data, at position: Data.Index, withStatus status: UInt8) throws -> (bytesRead: UInt32, event: SysExEvent) {
    if (status != 0xf0 && status != 0xf7) {
        throw ParseError.unexpectedStatus(actual: status)
    }
    
    let (bytesRead, data) = try buffer.readVariableLengthData(position)
    
    return (bytesRead,
        status == 0xF0
        ? SysExEvent.initial(SysExEventInitial(buffer: data))
        : SysExEvent.continued(SysExEventContinued(buffer: data))
    )
}

