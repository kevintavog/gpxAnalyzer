import Foundation
import Utility
import SwiftyXML
import GpxAnalyzerCore

// info <somefile>.gpx

public class TimeCommand: Command {
    public let command = "time"
    public let overview = "Output a GPX with the subset of points in the [start] and [end] times"
    private let inputFileArgument: OptionArgument<String>
    private let outputFileArgument: OptionArgument<String>
    private let startTimeArgument: OptionArgument<String>
    private let endTimeArgument: OptionArgument<String>
    let formatterWithHour = DateFormatter()


    public required init(parser: ArgumentParser) {
        let subparser = parser.add(subparser: command, overview: overview)
        inputFileArgument = subparser.add(option: "-i", kind: String.self, usage: "The GPX file to filter.")
        outputFileArgument = subparser.add(option: "-o", kind: String.self, usage: "The (GPX) file to write to.")
        startTimeArgument = subparser.add(option: "-s", kind: String.self, usage: "The start time, as HH:MM:SS")
        endTimeArgument = subparser.add(option: "-e", kind: String.self, usage: "The end time, as HH:MM:SS")

        formatterWithHour.dateFormat = "HH:mm:ss"
        formatterWithHour.timeZone = TimeZone(secondsFromGMT: 0)
    }

    public func run(with arguments: ArgumentParser.Result) throws {
        guard let inputName = arguments.get(inputFileArgument) else {
            print("The input file must be specified")
            return
        }
        guard let outputName = arguments.get(outputFileArgument) else {
            print("The output file must be specified")
            return
        }
        guard let start = arguments.get(startTimeArgument) else {
            print("The start time must be specified")
            return
        }
        guard let end = arguments.get(endTimeArgument) else {
            print("The end time must be specified")
            return
        }

        if inputName == outputName {
            throw GpxFilterCoreError("The output name must be different than the input name")
        }

        let startDate = try parseTime(start)
        let endDate = try parseTime(end)

        // The input file must exist
        let tracks = try InfoCommand.loadFile(inputName)

        // Walk through the GPX, collecting matching points
        var filteredPoints = [GpxPoint]()
        for t in tracks {
            for s in t.segments {
                filteredPoints += s.points.filter {
                    if let t = formatterWithHour.date(from: formatterWithHour.string(from: $0.time)) {
                        return t >= startDate && t <= endDate
                    }
                    return false
                }
            }
        }

        let outputFormatter = DateFormatter()
        outputFormatter.dateStyle = .none
        outputFormatter.timeStyle = .medium
        let xmlString = constructXml(filteredPoints)
        try xmlString.write(to: URL(fileURLWithPath: outputName), atomically: false, encoding: .utf8)
        print("Saved \(filteredPoints.count) points between \(outputFormatter.string(from: startDate)) " +
            "and \(outputFormatter.string(from: endDate)) to \(outputName)")
    }

    func constructXml(_ points: [GpxPoint]) -> String {
        let timeFormatter = ISO8601DateFormatter()

        let segment = XML(name: "trkseg")
        for p in points {
            let px = XML(name: "trkpt")
            px.addAttribute(name: "lat", value: p.latitude)
            px.addAttribute(name: "lon", value: p.longitude)

            px.addChild(XML(name: "ele", value: "\(p.elevation)"))
            px.addChild(XML(name: "time", value: "\(timeFormatter.string(from: p.time))"))
            px.addChild(XML(name: "course", value: "\(p.course)"))
            px.addChild(XML(name: "speed", value: "\(p.speed)"))

            if let fix = p.fix {
                px.addChild(XML(name: "fix", value: "\(fix)"))
            }
            if let hdop = p.hdop {
                px.addChild(XML(name: "hdop", value: "\(hdop)"))
            }
            if let pdop = p.pdop {
                px.addChild(XML(name: "pdop", value: "\(pdop)"))
            }
            if let vdop = p.vdop {
                px.addChild(XML(name: "vdop", value: "\(vdop)"))
            }

            segment.addChild(px)
        }

        let track = XML(name: "trk")
        track.addChild(segment)

        let xml = XML(name: "gpx")
        xml.addAttribute(name: "version", value: "1.0")
        xml.addAttribute(name: "xmlns", value: "http://www.topografix.com/GPX/1/0")
        xml.addAttribute(name: "creator", value: "GpxFilter - https://github.com/kevintavog/gpxAnalyzer")
        xml.addChild(track)

        return "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" + xml.toXMLString()
    }

    func parseTime(_ time: String) throws -> Date {
        if let hour = formatterWithHour.date(from: time) {
            return hour
        }

        throw GpxFilterCoreError("Unable to parse '\(time)'")
    }
}
