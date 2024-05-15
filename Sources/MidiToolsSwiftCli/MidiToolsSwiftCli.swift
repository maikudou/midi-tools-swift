import ArgumentParser
import Foundation
import MidiToolsSwift

@main
struct MidiTools: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "MidiTools",
        subcommands: [Info.self])
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
            
            print("\nStandart MIDI file, type \(header.type)")
            print("Number of tracks: \(header.tracksCount)")
            
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
}

