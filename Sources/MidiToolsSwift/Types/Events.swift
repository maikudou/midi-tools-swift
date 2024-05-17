//
//  Events.swift
//
//
//  Created by Mikhail Labanov on 5/2/24.
//

import Foundation

public protocol Event : Equatable {
    var status: UInt8 {get}
}

public struct Track {
    public var number: UInt16
    public var events: [(deltaTime: UInt32, any Event)]
}

public struct MIDIFile {
    var type: UInt8
    var tracks: [Track]
}

// MARK: - MetaEvents
/**
 * Meta events do not correspond to any particular channel by themselves,
 * but can be linked to a channel if preceeded with a ChannelPrefix event
 * They always have status byte of 0xff
 */
public protocol MetaEvent : Event, Equatable {
    var type: UInt8 {get}
}
public extension MetaEvent {
    var status: UInt8 {return 0xFF}
}

public struct SequenceNumberMetaEvent : MetaEvent {
    public var type: UInt8 {return 0x00}
    public var sequenceNumber: UInt16
}

public protocol TextEvent : MetaEvent {
    var text: String {get}
}

/**
 * There are 7 different text meta-events:
 */
public struct TextMetaEvent : TextEvent {
    public var type: UInt8 {return 0x01}
    public var text: String
}

public struct CopyrightNoticeMetaEvent : TextEvent  {
    public var type: UInt8 {return 0x02}
    public var text: String
}

public struct SequenceOrTrackNameMetaEvent : TextEvent {
    public var type: UInt8 {return 0x03}
    public var text: String
}

public struct InstrumentNameMetaEvent : TextEvent {
    public var type: UInt8 {return 0x04}
    public var text: String
}

public struct LyricMetaEvent : TextEvent {
    public var type: UInt8 {return 0x05}
    public var text: String
}

public struct MarkerMetaEvent : TextEvent {
    public var type: UInt8 {return 0x06}
    public var text: String
}

public struct CuePointMetaEvent : TextEvent {
    public var type: UInt8 {return 0x07}
    public var text: String
}

public struct ProgramNameMetaEvent : TextEvent {
    public var type: UInt8 {return 0x08}
    public var text: String
}

public struct DeviceNameMetaEvent : TextEvent {
    public var type: UInt8 {return 0x09}
    public var text: String
}



/**
 * From MIDI spec:
 * The MIDI channel (0-15) contained in this event may be used to associate
 * a MIDI channel with all events which follow, including System Exclusive
 * and meta-events. This channel is "effective" until the next normal MIDI event
 * (which contains a channel) or the next MIDI Channel Prefix meta-event.
 */
public struct ChannelPrefixMetaEvent : MetaEvent {
    public var type: UInt8 {return 0x20}
    public var channelPrefix: UInt8
}

public struct PortPrefixMetaEvent : MetaEvent {
    public var type: UInt8 {return 0x21}
    public var portPrefix: UInt8
}

public struct EndOfTrackMetaEvent : MetaEvent {
    public var type: UInt8 {return 0x2f}
}

struct SetTempoMetaEvent : MetaEvent {
    public var type: UInt8 {return 0x51}
    public var tempo: Tempo
}

public struct SFMPTEOffsetMetaEvent : MetaEvent {
    public var type: UInt8 {return 0x54}
    public var offset: SFMPTEOffset
}

public struct TimeSignatureMetaEvent : MetaEvent {
    public var type: UInt8 { return 0x58}
    public var timeSignature: TimeSignature
}

public struct KeySignatureMetaEvent : MetaEvent {
    public var type: UInt8 {return 0x59}
    public var keySignature: KeySignature
}

public struct SequencerSpecificMetaEvent : MetaEvent {
    public var type: UInt8 {return 0x7f}
    public var manufacturerId: String
    public var data: Data?
}

public struct UnknownMetaEvent : MetaEvent {
    public var type: UInt8
    public var data: Data?
}

// MARK: - SysExEvents
public struct SysExEventInitial : Event, Equatable {
    public var status: UInt8 {return 0xf0}
    public var buffer: Data
}

public struct SysExEventContinued : Event, Equatable {
    public var status: UInt8 {return 0xf7}
    public var buffer: Data
}

public enum SysExEvent: Equatable {
    case initial(SysExEventInitial)
    case continued(SysExEventContinued)
}

// MARK: - Channel Events
/**
 * Channel events do not have channel number in data,
 * instead, they have it as second nibble, for example:
 * Program change for channel would be 0xc1
 * Note-on for channel 1 — 0x80
 * Probably that's why MIDI has only 16 channels
 */
public protocol ChannelEvent : Event {
    var status: UInt8 {get}
    var channel: UInt8 {get}
}

public protocol NoteEvent {
    var note: UInt8 {get}
    var velocity: UInt8 {get}
}

public struct NoteOnEvent : NoteEvent, ChannelEvent {
    public var status: UInt8 {return 0x90 + self.channel}
    public var channel: UInt8
    public var note: UInt8
    public var velocity: UInt8
}

public struct NoteOffEvent : NoteEvent, ChannelEvent {
    public var status: UInt8 {return 0x80 + self.channel}
    public var channel: UInt8
    public var note: UInt8
    public var velocity: UInt8
}

public struct PolyphonicAftertouchEvent : ChannelEvent {
    public var status: UInt8 {return 0xA0 + self.channel}
    public var channel: UInt8
    public var note: UInt8
    public var pressure: UInt8
}

public struct ChannelAftertouchEvent : ChannelEvent {
    public var status: UInt8 {return 0xD0 + self.channel}
    public var channel: UInt8
    public var pressure: UInt8
}

public struct PitchBendEvent : ChannelEvent {
    public var status: UInt8 {return 0xE0 + self.channel}
    public var channel: UInt8
    public var bend: Int16
}

public struct ProgramChangeEvent : ChannelEvent {
    public var status: UInt8 {return 0xC0 + self.channel}
    public var channel: UInt8
    public var program: UInt8
}

public enum ControlEventKind {
    case MSB, LSB, SingleByte, Empty
}
/**
 * Control events with first status nibble 0xb can consist
 * of two consecutive events with different id,
 * one can state MSB byte another — LSB one.
 * As each data byte only has data 7 bits, resulting
 * value is 14 bits, 16384 steps, 16383 being the maximum.
 * LSB may be omitted, if there is no such event emmediately
 * after MSB, only 0-128 steps resolution is used, 127 is the maximum
 * value of a controlled parameter
 */
public struct ControlEvent : ChannelEvent {
    public var status: UInt8 {return 0xB0 + self.channel}
    public var channel: UInt8
    public var control: UInt8
    public var value: UInt8?
    public var kind: ControlEventKind
}

// MARK: - Global Events
public struct MTCQuarterFrameEvent : Event {
    public var status: UInt8 {return 0xF1}
    public var part: UInt8
    public var value: UInt8
}

public struct SongPositionChangeEvent : Event {
    public var status: UInt8 {0xF2}
    public var position: UInt16
}

public struct SongSelectEvent : Event {
    public var status: UInt8 {0xF3}
    public var song: UInt8
}

public struct TuneRequestEvent : Event {
    public var status: UInt8 {0xF6}
}

public struct TimingClockEvent : Event {
    public var status: UInt8 {0xF8}
}

public struct StartEvent : Event {
    public var status: UInt8 {0xFA}
}

public struct ContinueEvent : Event {
    public var status: UInt8 {0xFB}
}

public struct StopEvent : Event {
    public var status: UInt8 {0xFC}
}

public struct ActiveSensingEvent : Event {
    public var status: UInt8 {0xFE}
}

public struct SystemResetEvent : Event {
    public var status: UInt8 {0xFF}
}
