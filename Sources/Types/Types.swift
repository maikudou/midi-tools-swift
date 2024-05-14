//
//  Types.swift
//
//
//  Created by Mikhail Labanov on 5/2/24.
//

import Foundation

struct Tempo : Equatable {
    var microsecondsPerQuarterNote: UInt32
    var beatsPerMinute: UInt16
}

struct SFMPTEOffset : Equatable {
    var hours: UInt8
    var minutes: UInt8
    var seconds: UInt8
    var frames: UInt8
    var fractionalFrames: UInt8
}

struct TimeSignature : Equatable {
    var numerator: UInt8
    var denominator: UInt8
    var clocksPerClick: UInt8
    var bb: UInt8
}

struct KeySignature : Equatable {
    var flats: UInt8
    var sharps: UInt8
    var major: Bool
}

struct DivisionTimeCode: Equatable {
    var fps: Int8
    var ticksPerFrame: UInt8
}

struct DivisionMetric: Equatable {
    var ticksPerQuarterNote: UInt16
}

enum Division: Equatable {
    case timeCode(DivisionTimeCode)
    case metric(DivisionMetric)
}

struct Header: Equatable {
    var length: UInt32
    var type: UInt16
    var tracksCount: UInt16
    var division: Division
}

struct SequencerSpecificData : Equatable {
    var manufacturerId: String
    var data: Data?
}

enum ParseError: Error, Equatable {
    case outOfBounds
    case invalidHeader
    case invalidTrackPrefix
    case invalidEnumMember
    case invalidFileType(fileType: UInt16)
    case unexpectedValue(expected: Int, actual: Int)
    case unexpectedStatus(actual: UInt8)
}
