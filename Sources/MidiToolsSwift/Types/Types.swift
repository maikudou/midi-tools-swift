//
//  Types.swift
//
//
//  Created by Mikhail Labanov on 5/2/24.
//

import Foundation

public struct Tempo : Equatable {
    var microsecondsPerQuarterNote: UInt32
    var beatsPerMinute: UInt16
}

public struct SFMPTEOffset : Equatable {
    var hours: UInt8
    var minutes: UInt8
    var seconds: UInt8
    var frames: UInt8
    var fractionalFrames: UInt8
}

public struct TimeSignature : Equatable {
    var numerator: UInt8
    var denominator: UInt8
    var clocksPerClick: UInt8
    var bb: UInt8
}

public struct KeySignature : Equatable {
    var flats: UInt8
    var sharps: UInt8
    var major: Bool
}

public struct DivisionTimeCode: Equatable {
    var fps: Int8
    var ticksPerFrame: UInt8
}

public struct DivisionMetric: Equatable {
    var ticksPerQuarterNote: UInt16
}

public enum Division: Equatable {
    case timeCode(DivisionTimeCode)
    case metric(DivisionMetric)
}

public struct Header: Equatable {
    public var length: UInt32
    public var type: UInt16
    public var tracksCount: UInt16
    public var division: Division
}

public struct SequencerSpecificData : Equatable {
    var manufacturerId: String
    var data: Data?
}

public enum ParseError: Error, Equatable {
    case outOfBounds
    case invalidHeader
    case invalidTrackPrefix
    case invalidEnumMember
    case invalidFileType(fileType: UInt16)
    case unexpectedValue(expected: Int, actual: Int)
    case unexpectedStatus(actual: UInt8)
}

public enum ConvertError: Error {
    case unexpectedType
    case alreadyCorrectType
}
