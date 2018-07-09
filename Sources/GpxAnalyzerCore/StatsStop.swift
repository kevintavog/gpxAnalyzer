import Foundation

public enum StatsStopStyle: String, Codable {
    case paused = "paused"
    case stopped = "stopped"
}


public class StatsStop : Codable, CustomStringConvertible {
    public let style: StatsStopStyle
    public let latitude: Double
    public let longitude: Double
    public let startTime: Date
    public let endTime: Date
    public let durationSeconds: Double
    public var minLat: Double
    public var minLon: Double
    public var maxLat: Double
    public var maxLon: Double
    public var distance: Double


    init(style: StatsStopStyle, points: [GpxPoint]) {
        self.style = style
        self.startTime = points[0].time
        self.endTime = points[points.count - 1].time
        self.durationSeconds = points[0].seconds(between: points[points.count - 1])

        var minLatitude = points[0].latitude
        var maxLatitude = points[0].latitude
        var minLongitude = points[0].longitude
        var maxLongitude = points[0].longitude
        var prevPoint = points[0]
        for p in points {
            minLatitude = min(p.latitude, minLatitude)
            maxLatitude = max(p.latitude, maxLatitude)
            minLongitude = min(p.longitude, minLongitude)
            maxLongitude = max(p.longitude, maxLongitude)
        }

        self.minLat = minLatitude
        self.maxLat = maxLatitude
        self.minLon = minLongitude
        self.maxLon = maxLongitude
        self.distance = points[0].distance(to: points[points.count - 1])

        self.latitude = self.minLat + ((self.maxLat - self.minLat) / 2.0)
        self.longitude = self.minLon + ((self.maxLon - self.minLon) / 2.0)
    }

    public init(first: StatsStop, second: StatsStop) {
        self.startTime = min(first.startTime, second.startTime)
        self.endTime = max(first.endTime, second.endTime)
        self.durationSeconds = abs(startTime.timeIntervalSince(endTime))
        self.style = self.durationSeconds < GpxAnalyzer.minimumStopDurationSeconds ? StatsStopStyle.paused : StatsStopStyle.stopped

        self.minLat = min(first.minLat, second.minLat)
        self.maxLat = max(first.maxLat, second.maxLat)
        self.minLon = min(first.minLon, second.minLon)
        self.maxLon = max(first.maxLon, second.maxLon)
        self.distance = first.distance + second.distance

        self.latitude = self.minLat + ((self.maxLat - self.minLat) / 2.0)
        self.longitude = self.minLon + ((self.maxLon - self.minLon) / 2.0)
    }

    public var description: String {
        return "\(style) @\(latitude), \(longitude), for \(durationSeconds) seconds, starting at \(startTime)"
    }
}
