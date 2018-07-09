
// Given a GPX track:
//  Load it
//      There are 1 or more Tracks, each has 1 or more Segments, each has 1 or more Points
//  Analyze it
//      Remove points with hpop/dpop > 2 (& track those removed)
//      Split into runs when time difference is > 5 or 10 seconds
//      Get rid of short runs (< 5 or 10 points) (& track those removed)
//      Calculate max speed (& track those removed)
//          Remove top 5% points by distance between points
//          Remove top 5% points by speed
//      Smooth speed using weighted average
//      Smooth track lat/lon using weighted positional average
//      Deduce activity per run
//          Determine average speed for a run, give weight per possible activity
//          Use max speed AND/OR relative speed (multiplier between average & max) to decide on activity

//  Save it
//      There are 1 or more Tracks, each with 1 or more Runs
//      There are 0 or more BadDataRuns - the points tossed out during analysis


import Foundation
import SwiftyXML
import GpxAnalyzerCore


if CommandLine.arguments.count != 3 {
    print("Pass a two arguments, the name of a GPX file and the name of the output file")
    exit(-1)
}

let filename = CommandLine.arguments[1]
let outputName = CommandLine.arguments[2]
print("Loading \(filename) and writing to \(outputName)")

do {
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

    let stats = GpxAnalyzer.generateStats(gpxTracks: gpxTracks)

print("output:")
    for t in stats.tracks {
        var lat = 0.0
        var lon = 0.0
        if t.runs.count > 0 {
            lat = t.runs[0].points[0].gpx.latitude
            lon = t.runs[0].points[0].gpx.longitude
        }

        print("track: \(t) (\(lat),\(lon))")
        print("  > there are \(t.runs.count) runs, \(t.stops.count) stops and \(t.discardedPoints.count) discarded points")
        // for r in t.runs {
        //     let speed = r.kilometers / (r.seconds / 3600.0)
        //     print("  >> [\(r.style)] run \(r.points[0].gpx.time) \(r.kilometers) km in \(r.seconds) secs: \(speed) --> \(Int(r.speedTypes[0].probability * 100))% \(r.speedTypes[0].transportation)")
        // }

        var prevStop: StatsStop?
        var combinedStop: StatsStop?
        for s in t.stops {
            print("  >> [\(s.style) \(s.startTime) to \(s.endTime) for \(Int(s.durationSeconds))")
            prevStop = s
        }
    }

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let jsonData = try encoder.encode(stats)
    let json = String(data: jsonData, encoding: .utf8)!
    try json.write(to: URL(fileURLWithPath: outputName), atomically: false, encoding: .utf8)

} catch {
    print("ERROR: \(error)")
}
