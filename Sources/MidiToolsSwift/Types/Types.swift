//
//  Types.swift
//
//
//  Created by Mike Henkel on 5/2/24.
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
    public var type: UInt16
    public var tracksCount: UInt16
    public var division: Division
    public var extraData: Data?
    
    public var rawData: Data {
        get {
            var data = "MThd".data(using: .isoLatin1)!
            data.appendUInt32BE(UInt32(6 + (self.extraData != nil ? self.extraData!.count : 0)))
            data.appendUInt16BE(self.type)
            data.appendUInt16BE(self.tracksCount)
            
            switch self.division {
            case .timeCode(let divisionTimeCode):
                data.append(
                    Data([
                        UInt8(truncatingIfNeeded: ~divisionTimeCode.fps + 1),
                        divisionTimeCode.ticksPerFrame
                    ])
                )
            case .metric(let divisionMetric):
                data.appendUInt16BE(divisionMetric.ticksPerQuarterNote)
            }
            
            if self.extraData != nil {
                data.append(self.extraData!)
            }
            return data
        }
    }
    
    public init(type: UInt16, tracksCount: UInt16, division: Division, extraData: Data?) {
        self.type = type
        self.tracksCount = tracksCount
        self.division = division
        self.extraData = extraData
    }
    
    public init(type: UInt16, tracksCount: UInt16, division: Division) {
        self.type = type
        self.tracksCount = tracksCount
        self.division = division
    }
}

public struct SequencerSpecificData : Equatable {
    var manufacturerId: String
    var data: Data?
}

public struct Track {
    public var number: UInt16
    public var events: [TrackEvent]
    public var rawData: Data {
        get {
            return encodeTrack(from: events, with: number)
        }
    }
    
    public init(number: UInt16, events: [TrackEvent]) {
        self.number = number
        self.events = events
    }
}

public struct MIDIFile {
    var header: Header
    var tracks: [Track]
    var metadata: Metadata?
}

public struct Metadata {
    var name: String?
    var artist: String?
    var album: String?
    var year: String?
    var compilation: Bool?
    var genre: String?
    var trackIndex: Int?  // Number of the track in an album/compilation
    var trackNumber: Int? // Total number of tracks in an album/compilation
    var composer: String?
    var comment: String?
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
    case notImplemented
}

