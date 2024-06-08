//
//  Write.swift
//
//
//  Created by Mike Henkel on 5/5/24.
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

let TRACK_CHUNK_TYPE = Data([0x4d, 0x54, 0x72, 0x6b])

func encodeTrack(from events: [TrackEvent], with number: UInt16) -> Data {
    var data = Data()
    data.append(TRACK_CHUNK_TYPE)
    
    var runningStatus: UInt8? = nil
    
    var restOfData = Data()
    
    for (deltaTime, event) in events {
        restOfData.append(encodeVariableQuantity(quantity: deltaTime))
        switch event {
        case is any MetaEvent:
            // append all data for meta-events always
            restOfData.append(event.rawData)
            continue
        default:
            if runningStatus != nil && event.status == runningStatus! {
                // append only bytes starting from second
                restOfData.append(event.rawData[1...])
            } else {
                if event is any ChannelEvent {
                    runningStatus = event.status
                }
                // append all bytes
                restOfData.append(event.rawData)
            }
        }
    }
    
    data.appendUInt32BE(UInt32(restOfData.count))
    data.append(restOfData)
    
    return data
}

func encodeTextMetaEvent(
    _ event: any TextEvent
) -> Data {
    var data = Data([event.status, event.type])
    data.append(encodeVariableQuantity(quantity: UInt32(event.text.count)))
    data.append(event.text.data(using: .isoLatin1) ?? Data())
    return data
}

func encodeSequencerSpecificMetaEvent(
    _ event: SequencerSpecificMetaEvent
) -> Data {
    var data = Data([
        event.status,
        event.type
    ])
    
    let lengthData = encodeVariableQuantity(
        quantity: UInt32(event.manufacturerId.count/2) + UInt32(event.data?.count ?? 0)
    )
    
    data.append(lengthData)
    
    data.append(event.manufacturerId.enumerated().reduce(Data(), { acc, value in
        if (value.offset % 2 != 0) {
            var newAcc = Data(acc)
            let index = String.Index(utf16Offset: value.offset, in: event.manufacturerId)
            let startIndex = String.Index(utf16Offset: value.offset-1, in: event.manufacturerId)
            newAcc.append(Data([UInt8(event.manufacturerId[startIndex...index], radix: 16)!]))
            return newAcc
        } else {
            return acc
        }
    }))
    
    
    if (event.data != nil) {
        data.append(event.data!)
    }
    
    return data
}

public func splitEventsByChannel(
    _ incomingEvents: [TrackEvent]
) -> Dictionary<UInt8, [(deltaTime: UInt32, event: any Event)]> {
    var events = Dictionary<UInt8, [TrackEvent]>()
    var absoluteTimes = Dictionary<UInt8, Int>()
    
    var time = 0
    var currentChannel: UInt8 = 0
    var channelPrefix: UInt8? = nil
    
    for (deltaTime, event) in incomingEvents {
        time += Int(deltaTime)
        
        switch event {
        case let metaEvent as any MetaEvent:
            switch metaEvent {
            case let channelPrefixMetaEvent as ChannelPrefixMetaEvent:
                channelPrefix = channelPrefixMetaEvent.channelPrefix
                currentChannel = channelPrefix!
            case is EndOfTrackMetaEvent:
                continue
            default:
                // put all meta-events into channel 0 unless
                // there is a channel prefix
                currentChannel = channelPrefix == nil
                ? 0 : channelPrefix!
            }
        case let channelEvent as any ChannelEvent:
            currentChannel = channelEvent.channel
            channelPrefix = nil
        default:
            // put all non-channel events into channel 0 unless
            // there is a channel prefix
            currentChannel = channelPrefix == nil
            ? 0 : channelPrefix!
        }
        
        if (!events.keys.contains(currentChannel)) {
            events.updateValue([], forKey: currentChannel)
        }
        
        events[currentChannel]!.append(
            (UInt32(time - (absoluteTimes[currentChannel] ?? 0)), event)
        )
        
        absoluteTimes.updateValue(time, forKey: currentChannel)
    }
    
    return events
}

public func joinTracks(_ tracks: [Track]) -> Track {
    var events: [TrackEvent] = []
    let heap = Heap<(time: Int, event: any Event)>(compareBy: {
        $0.event is any MetaEvent || $0.time < $1.time
    })

    for track in tracks {
        var time = 0
        for (deltaTime, event) in track.events {
            time += Int(deltaTime)
            heap.insert((time, event))
        }
    }
    
    var currentTime = 0
    while let (time, event) = heap.pop() {
        events.append((UInt32(time-currentTime), event))
        currentTime = time
    }
    
    return Track(number: 0, events: events)
}
