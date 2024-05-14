//
//  Write.swift
//
//
//  Created by Mikhail Labanov on 5/5/24.
//

import Foundation

func joinNibbles(MSN: UInt8, LSN: UInt8) -> UInt8 {
  return ((MSN & 0xf) << 4) + (LSN & 0xf)
}

func encodeVariableQuantity(quantity: UInt32) -> Data {
    var value = quantity
    var buffer = Data([UInt8(truncatingIfNeeded: value & 0x7f)])
    value = value >> 7
    while (value > 0) {
        buffer.append(Data([UInt8(truncatingIfNeeded: (value & 0x7f) | 0x80)]))
        value = value >> 7
    }
    buffer.reverse()
    return buffer
}
