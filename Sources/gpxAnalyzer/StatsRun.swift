import Foundation

enum RunStyle: String, Codable {
    case track = "track"
    case virtual = "virtual"
}

class StatsRun : Codable, CustomStringConvertible {
    static private var dateFormatter: DateFormatter?

    let style: RunStyle
    var speedTypes: [SpeedType] = [SpeedType]()
    var points: [StatsPoint]
    var minLat: Double = 0.0
    var minLon: Double = 0.0
    var maxLat: Double = 0.0
    var maxLon: Double = 0.0
    var kilometers: Double = 0.0
    var seconds: Double = 0.0
    var trackOffsetSeconds: Double = 0.0
    var trackOffsetKilometers: Double = 0.0

    init(style: RunStyle) {
        if StatsRun.dateFormatter == nil {
            StatsRun.dateFormatter = DateFormatter()
            StatsRun.dateFormatter?.dateFormat = "yyyy-MM-dd HH:mm:ss"
        }

        self.style = style
        self.points = [StatsPoint]()
    }

    func add(gpx: GpxPoint) {
        var kmFromLast = 0.0
        if points.count == 0 {
            minLat = gpx.latitude
            minLon = gpx.longitude
            maxLat = gpx.latitude
            maxLon = gpx.longitude
            kilometers = 0.0
            seconds = 0.0
        } else {
            minLat = min(gpx.latitude, minLat)
            minLon = min(gpx.longitude, minLon)
            maxLat = max(gpx.latitude, maxLat)
            maxLon = max(gpx.longitude, maxLon)
            seconds = gpx.seconds(between: points[0].gpx)
            kmFromLast = gpx.distance(to: points[points.count - 1].gpx)
            kilometers += kmFromLast
        }

        points.append(StatsPoint(gpx: gpx, kilometersIntoRun: kilometers, secondsIntoRun: seconds, kilometersFromLast: kmFromLast))
    }

    var description: String {
        let startTime = StatsRun.dateFormatter!.string(from: points.last!.gpx.time)
        return "\(style): \(points.count) points, from \(startTime) for \(seconds) seconds and \(Int(kilometers * 1000.0)) meters"
    }
}
