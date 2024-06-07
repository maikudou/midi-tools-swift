//
//  Strings.swift
//
//
//  Created by Mike Henkel on 5/13/24.
//

import Foundation

public func metaEventHumanReadableString(
  _ eventType: UInt8
) -> String {
  switch (eventType) {
    case 0x00:
      return "Sequence Number"
    case 0x01:
      return "Text"
    case 0x02:
      return "Copyright Notice"
    case 0x03:
      return "Sequence/Track Name"
    case 0x04:
      return "Instrument Name"
    case 0x05:
      return "Lyric"
    case 0x06:
      return "Marker"
    case 0x07:
      return "Cue Point"
    case 0x20:
      return "MIDI Channel Prefix"
    case 0x2f:
      return "End of Track"
    case 0x51:
      return "Set Tempo"
    case 0x54:
      return "SMPTE Offset"
    case 0x58:
      return "Time Signature"
    case 0x59:
      return "Key Signature"
    case 0x7f:
      return "Sequencer-Specific"
    default:
      return "Unknown Meta-event"
  }
}
