import ArgumentParser
import Foundation
import MidiToolsSwift
import MidiManufacturers

@main
struct MidiTools: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "MidiTools",
        subcommands: [Info.self, Convert.self])
}

extension MidiTools {
    struct Info: ParsableCommand {
        @Argument(help: "Specify the input file.")
        public var inputFile: String
        
        @Flag(name: .shortAndLong, help: "Show detailed information.")
        var detailed = false
        
        @Flag(name: .shortAndLong, help: "Show all text events.")
        var texts = false
        
        public func run() throws {
            let fileUrl = URL(fileURLWithPath: self.inputFile)
            let buffer = try Data(contentsOf: fileUrl)
            
            print("Parsing \(fileUrl.absoluteString)...")
            
            let (bytesRead, header) = try readHeader(from: buffer)
            
            print("\nStandart MIDI file Type \(header.type)\n")
            
            var position = bytesRead
            
            if (detailed) {
                var textEvents: [any TextEvent] = []
                var copyrightNotices: [String] = []
                var sysexVendors = Set<String>()
                
                for trackNumber in 0..<header.tracksCount {
                    let (bytesRead, track) = try readTrack(
                        number: trackNumber,
                        from: buffer,
                        at: Int(position)
                    )
                    
                    var trackName: String = "Unnamed"
                    
                    for (_, event) in track.events {
                        if (event is any TextEvent) {
                            let textEvent: any TextEvent = event as! any TextEvent
                            
                            if (texts) {
                                textEvents.append(textEvent)
                            }
                            var textMatchesCopyright = false
                            if #available(macOS 13.0, *) {
                                let copyrightRegex = try Regex("\\(c\\)|©")
                                textMatchesCopyright = textEvent.text.contains(copyrightRegex)
                            }
                            if (textEvent is CopyrightNoticeMetaEvent || textMatchesCopyright) {
                                copyrightNotices.append(textEvent.text)
                            }
                            if (textEvent is SequenceOrTrackNameMetaEvent) {
                                trackName = textEvent.text
                            }
                        }
                        
                        if (event is SequencerSpecificMetaEvent) {
                            sysexVendors.insert((event as! SequencerSpecificMetaEvent).manufacturerId)
                        }
                        if (event is SysExEventInitial) {
                            let sysexEvent = event as! SysExEventInitial
                            let manufacturerId = (sysexEvent.buffer[0] == 0
                                                  ? sysexEvent.buffer.subdata(in: Range(0...2))
                                                  : sysexEvent.buffer.subdata(in: Range(0...0)))
                                .map {String(format: "%02hhx", $0)}.joined()
                            
                            sysexVendors.insert(manufacturerId)
                        }
                    }
                    
                    print("\(header.type == 2 ? "Sequence" : "Track") #\(trackNumber + 1): \(trackName)")
                    
                    position += bytesRead
                }
                
                if (copyrightNotices.count > 0) {
                    print("\nCopyright notice: \(copyrightNotices.joined(separator: ", "))")
                }
                sysexVendors = sysexVendors.filter { MIDI_MANUFACTURERS[$0] != nil }
                if (sysexVendors.count > 0) {
                    print("\nFile has vendor specific data, vendors: ")
                    for sysexVendor in sysexVendors {
                        print(MIDI_MANUFACTURERS[sysexVendor]!)
                    }
                }
                if (texts) {
                    print("\nText events:")
                    for textEvent in textEvents {
                        print("\(metaEventHumanReadableString(textEvent.type)): \(textEvent.text)")
                    }
                }
            }
        }
    }
    
    struct Convert: ParsableCommand {
        @Argument(help: "Specify the input file.")
        public var inputFile: String
        
        @Argument(help: "Specify the output file.")
        public var outputFile: String
        
        @Option(name: .shortAndLong, help: "Output format, 0 | 1 | 2")
        var type: Int
        
        public func run() throws {
            let fileUrl = URL(fileURLWithPath: self.inputFile)
            let outputUrl = URL(fileURLWithPath: self.outputFile)
            print(fileUrl)
            let buffer = try Data(contentsOf: fileUrl)
            
            if (type > 2 || type < 0) {
                throw ConvertError.unexpectedType
            }
            
            print("Reading \(fileUrl.absoluteString)...")
            
            let (bytesRead, header) = try readHeader(from: buffer)
            
            if (header.type == type) {
                throw ConvertError.alreadyCorrectType
            }
            
            print("Converting...")
            
            // Convert from single track to multitrack
            if (header.type == 0 && type == 1) {
                var tracks: [Track] = []
                
                let (_, sourceTrack) = try readTrack(
                    number: 0,
                    from: buffer,
                    at: Int(bytesRead)
                )
                
                let events = splitEventsByChannel(sourceTrack.events)
                
                for channel in events.keys.sorted() {
                    if ((events[channel]?.count ?? 0) > 0) {
                        tracks.append(Track(number: UInt16(channel), events: events[channel]!))
                    }
                }
                
                let newHeader = Header(
                    type: UInt16(type),
                    tracksCount: UInt16(tracks.count),
                    division: header.division
                )
                
                var outputData = Data()
                outputData.append(newHeader.rawData)
                for track in tracks {
                    outputData.append(track.rawData)
                }
                
                print("Saving to \(outputUrl.absoluteString)...")
                try outputData.write(to: outputUrl)
            } else if (header.type == 1 && type == 0) {
                var position = bytesRead
                var tracks: [Track] = []
                
                for trackNumber in 0..<header.tracksCount {
                    let (bytesRead, track) = try readTrack(
                        number: trackNumber,
                        from: buffer,
                        at: Int(position)
                    )
                    tracks.append(track)
                    position += bytesRead
                }
                
                let newHeader = Header(
                    type: UInt16(type),
                    tracksCount: UInt16(1),
                    division: header.division
                )
                
                var outputData = Data()
                outputData.append(newHeader.rawData)
                outputData.append(joinTracks(tracks).rawData)
                
                print("Saving to \(outputUrl.absoluteString)...")
                try outputData.write(to: outputUrl)
            } else {
                throw ConvertError.notImplemented
            }
        }
    }
}

