import Foundation
import Utility
import SwiftyXML
import GpxAnalyzerCore

// info <somefile>.gpx

public class InfoCommand: Command {
    public let command = "info"
    public let overview = "Provide information about one or more GPX files"
    private let files: PositionalArgument<[String]>

    public required init(parser: ArgumentParser) {
        let subparser = parser.add(subparser: command, overview: overview)
        files = subparser.add(positional: "files", kind: [String].self, usage: "The GPX files to show information.")
    }

    public func run(with arguments: ArgumentParser.Result) throws {
        guard let filenames = arguments.get(files) else {
            print("At least one GPX file must be specified.")
            return
        }

        for f in filenames {
            let tracks = try InfoCommand.loadFile(f)
            print("\(f):")
            dumpInfo(tracks)
        }
    }

    func dumpInfo(_ tracks: [GpxTrack]) {
        if tracks.count == 0 {
            print(  "No tracks were found")
            return
        }

        for idx in 0..<tracks.count {
            let t = tracks[idx]
            let pointsCount = t.segments.reduce (0, { $0 + $1.points.count })
            print("  Track \(idx + 1) has \(t.segments.count) segment(s) and a total of \(pointsCount) points")
            for (segIndex, segment) in t.segments.enumerated() {
                var totalTimeSeconds = 0.0
                var totalDistance = 0.0
                var maxSpeedMS = 0.0
                var maxSpeedKmH = 0.0
                var maxDistanceBetweenPoints = 0.0
                var maxDistancePoint: GpxPoint? = nil
                var maxSpeedBetweenPoints = -0.01
                var maxSpeedPoint: GpxPoint? = nil

                if segment.points.count > 0 {
                    var prevPoint = segment.points[0]
                    for pointIndex in 1..<segment.points.count {
                        let p = segment.points[pointIndex]
                        totalTimeSeconds = p.seconds(between: segment.points[0])
                        totalDistance += p.distance(to: prevPoint)
                        maxSpeedMS = max(maxSpeedMS, p.speed)
                        maxSpeedKmH = max(maxSpeedMS, p.speedKmH)

                        if (p.distance(to: prevPoint) > maxDistanceBetweenPoints) {
                            maxDistanceBetweenPoints = p.distance(to: prevPoint)
                            maxDistancePoint = p
                        }

                        if (p.speed(between: prevPoint) > maxSpeedBetweenPoints) {
                            maxSpeedBetweenPoints = p.speed(between: prevPoint)
                            maxSpeedPoint = p
                        }

                        prevPoint = p
                    }
                }

                var maxConsecutive = ""
                if let p = maxDistancePoint {
                    maxConsecutive += ", max distance ending at \(p.time): \(Int(maxDistanceBetweenPoints * 1000)) meters"
                }
                if let p = maxSpeedPoint {
                    maxConsecutive += ", max calculated speed ending at \(p.time): \(maxSpeedBetweenPoints) k/h"
                }
                print("    Segment \(segIndex + 1) has \(segment.points.count) points, " +
                    "\(Int(totalTimeSeconds)) seconds, \(totalDistance) kilometers, \(maxSpeedKmH) max k/h\(maxConsecutive)")
                if segment.points.count > 0 {
                    print("       First point \(stringizePoint(segment.points.first!))")
                }
                if segment.points.count > 1 {
                    print("       Last point \(stringizePoint(segment.points.last!))")
                }
            }
        }
    }

    func stringizePoint(_ point: GpxPoint) -> String {
        var str = "\(point.time): \(point.latitude), \(point.longitude), speed: \(point.speed) m/s (\(point.speedKmH) km/h), " +
            "elevation: \(point.elevation) meters, course: \(point.course) degrees"
        if let fix = point.fix {
            str += ", fix: \(fix)"
        }
        if let hdop = point.hdop {
            str += ", hdop: \(hdop)"
        }
        if let pdop = point.pdop {
            str += ", pdop: \(pdop)"
        }
        if let vdop = point.vdop {
            str += ", vdop: \(vdop)"
        }
        return str
    }

    static func loadFile(_ filename: String) throws -> [GpxTrack] {
        let data = try Data(contentsOf: URL(fileURLWithPath: filename))
        let xml = XML(data: data)

        var gpxTracks = [GpxTrack]()
        for track in xml!["trk"] {
            var trackSegments = [GpxSegment]()
            for segment in track["trkseg"] {
                var segmentPoints = [GpxPoint]()
                for point in segment["trkpt"] {
                    segmentPoints.append(GpxPoint(xml: point))
                }
                trackSegments.append(GpxSegment(points: segmentPoints))
            }
            gpxTracks.append(GpxTrack(segments: trackSegments))
        }

        return gpxTracks
    }
}
