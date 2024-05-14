//
//  Events.swift
//
//
//  Created by Mikhail Labanov on 5/2/24.
//

import Foundation

protocol Event : Equatable {
    var status: UInt8 {get}
}

struct Track {
    var number: UInt16
    var events: [(deltaTime: UInt32, any Event)]
}

struct MIDIFile {
    var type: UInt8
    var tracks: [Track]
}

// MARK: - MetaEvents
/**
 * Meta events do not correspond to any particular channel by themselves,
 * but can be linked to a channel if preceeded with a ChannelPrefix event
 * They always have status byte of 0xff
 */
protocol MetaEvent : Event, Equatable {
    var type: UInt8 {get}
}
extension MetaEvent {
    var status: UInt8 {return 0xFF}
}

struct SequenceNumberMetaEvent : MetaEvent {
    var type: UInt8 {return 0x00}
    var sequenceNumber: UInt16
}

protocol TextEvent : MetaEvent {
    var text: String {get}
}

/**
 * There are 7 different text meta-events:
 */
struct TextMetaEvent : TextEvent {
    var type: UInt8 {return 0x01}
    var text: String
}

struct CopyrightNoticeMetaEvent : TextEvent  {
    var type: UInt8 {return 0x02}
    var text: String
}

struct SequenceOrTrackNameMetaEvent : TextEvent {
    var type: UInt8 {return 0x03}
    var text: String
}

struct InstrumentNameMetaEvent : TextEvent {
    var type: UInt8 {return 0x04}
    var text: String
}

struct LyricMetaEvent : TextEvent {
    var type: UInt8 {return 0x05}
    var text: String
}

struct MarkerMetaEvent : TextEvent {
    var type: UInt8 {return 0x06}
    var text: String
}

struct CuePointMetaEvent : TextEvent {
    var type: UInt8 {return 0x07}
    var text: String
}

/**
 * From MIDI spec:
 * The MIDI channel (0-15) contained in this event may be used to associate
 * a MIDI channel with all events which follow, including System Exclusive
 * and meta-events. This channel is "effective" until the next normal MIDI event
 * (which contains a channel) or the next MIDI Channel Prefix meta-event.
 */
struct ChannelPrefixMetaEvent : MetaEvent {
    var type: UInt8 {return 0x20}
    var channelPrefix: UInt8
}

struct EndOfTrackMetaEvent : MetaEvent {
    var type: UInt8 {return 0x2f}
}

struct SetTempoMetaEvent : MetaEvent {
    var type: UInt8 {return 0x51}
    var tempo: Tempo
}

struct SFMPTEOffsetMetaEvent : MetaEvent {
    var type: UInt8 {return 0x54}
    var offset: SFMPTEOffset
}

struct TimeSignatureMetaEvent : MetaEvent {
    var type: UInt8 { return 0x58}
    var timeSignature: TimeSignature
}

struct KeySignatureMetaEvent : MetaEvent {
    var type: UInt8 {return 0x59}
    var keySignature: KeySignature
}

struct SequencerSpecificMetaEvent : MetaEvent {
    var type: UInt8 {return 0x7f}
    var manufacturerId: String
    var data: Data?
}

struct UnknownMetaEvent : MetaEvent {
    var type: UInt8
    var data: Data?
}

// MARK: - SysExEvents
struct SysExEventInitial : Event, Equatable {
    var status: UInt8 {return 0xf0}
    var buffer: Data
}

struct SysExEventContinued : Event, Equatable {
    var status: UInt8 {return 0xf7}
    var buffer: Data
}

enum SysExEvent: Equatable {
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
protocol ChannelEvent : Event {
    var status: UInt8 {get}
    var channel: UInt8 {get}
}

protocol NoteEvent {
    var note: UInt8 {get}
    var velocity: UInt8 {get}
}

struct NoteOnEvent : NoteEvent, ChannelEvent {
    var status: UInt8 {return 0x90 + self.channel}
    var channel: UInt8
    var note: UInt8
    var velocity: UInt8
}

struct NoteOffEvent : NoteEvent, ChannelEvent {
    var status: UInt8 {return 0x80 + self.channel}
    var channel: UInt8
    var note: UInt8
    var velocity: UInt8
}

struct PolyphonicAftertouchEvent : ChannelEvent {
    var status: UInt8 {return 0xA0 + self.channel}
    var channel: UInt8
    var note: UInt8
    var pressure: UInt8
}

struct ChannelAftertouchEvent : ChannelEvent {
    var status: UInt8 {return 0xD0 + self.channel}
    var channel: UInt8
    var pressure: UInt8
}

struct PitchBendEvent : ChannelEvent {
    var status: UInt8 {return 0xE0 + self.channel}
    var channel: UInt8
    var bend: Int16
}

struct ProgramChangeEvent : ChannelEvent {
    var status: UInt8 {return 0xC0 + self.channel}
    var channel: UInt8
    var program: UInt8
}

enum ControlEventKind {
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
struct ControlEvent : ChannelEvent {
    var status: UInt8 {return 0xB0 + self.channel}
    var channel: UInt8
    var control: UInt8
    var value: UInt8?
    var kind: ControlEventKind
}

// MARK: - Global Events
struct MTCQuarterFrameEvent : Event {
    var status: UInt8 {return 0xF1}
    var part: UInt8
    var value: UInt8
}

struct SongPositionChangeEvent : Event {
    var status: UInt8 {0xF2}
    var position: UInt16
}

struct SongSelectEvent : Event {
    var status: UInt8 {0xF3}
    var song: UInt8
}

struct TuneRequestEvent : Event {
    var status: UInt8 {0xF6}
}

struct TimingClockEvent : Event {
    var status: UInt8 {0xF8}
}

struct StartEvent : Event {
    var status: UInt8 {0xFA}
}

struct ContinueEvent : Event {
    var status: UInt8 {0xFB}
}

struct StopEvent : Event {
    var status: UInt8 {0xFC}
}

struct ActiveSensingEvent : Event {
    var status: UInt8 {0xFE}
}

struct SystemResetEvent : Event {
    var status: UInt8 {0xFF}
}
