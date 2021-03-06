import Foundation

public enum RunStyle: String, Codable {
    case track = "track"
    case virtual = "virtual"
}

public class StatsRun : Codable, CustomStringConvertible {
    static private var dateFormatter: DateFormatter?

    public let style: RunStyle
    public var speedTypes: [SpeedType] = [SpeedType]()
    public var points: [StatsPoint]
    public var minLat: Double = 0.0
    public var minLon: Double = 0.0
    public var maxLat: Double = 0.0
    public var maxLon: Double = 0.0
    public var kilometers: Double = 0.0
    public var seconds: Double = 0.0
    public var trackOffsetSeconds: Double = 0.0
    public var trackOffsetKilometers: Double = 0.0
    public var timezoneInfo = TimezoneInfo(id: "", tag: "")
    public var vectors = [Vector]()

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
        var bearing = -1
        var calculatedSpeed = -1.0
        if points.count == 0 {
            minLat = gpx.latitude
            minLon = gpx.longitude
            maxLat = gpx.latitude
            maxLon = gpx.longitude
            kilometers = 0.0
            seconds = 0.0
        } else {
            let prevPoint = points[points.count - 1]
            minLat = min(gpx.latitude, minLat)
            minLon = min(gpx.longitude, minLon)
            maxLat = max(gpx.latitude, maxLat)
            maxLon = max(gpx.longitude, maxLon)
            seconds = points[0].gpx.seconds(between: gpx)
            kmFromLast = prevPoint.gpx.distance(to: gpx)
            kilometers += kmFromLast
            bearing = prevPoint.gpx.bearing(to: gpx)
            calculatedSpeed = prevPoint.gpx.speed(between: gpx)
        }

        points.append(StatsPoint(
            gpx: gpx,
            bearing: bearing,
            kilometersIntoRun: kilometers,
            secondsIntoRun: seconds,
            kilometersFromLast: kmFromLast,
            calculatedSpeed: calculatedSpeed))
    }

    public var description: String {
        let startTime = StatsRun.dateFormatter!.string(from: points.last!.gpx.time)
        return "\(style): \(points.count) points, from \(startTime) for \(seconds) seconds and \(Int(kilometers * 1000.0)) meters"
    }
}
