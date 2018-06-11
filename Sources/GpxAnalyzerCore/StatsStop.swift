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

    init(style: StatsStopStyle, points: [GpxPoint]) {
        self.style = style
        self.startTime = points[0].time
        self.endTime = points[points.count - 1].time
        self.durationSeconds = points[0].seconds(between: points[points.count - 1])

        // Calculate a center point
        self.latitude = points.reduce(0.0, { $0 + $1.latitude }) / Double(points.count)
        self.longitude = points.reduce(0.0, { $0 + $1.longitude }) / Double(points.count)
    }

    init(first: StatsStop, second: StatsStop) {
        self.style = first.style            // Style may change (it's based on duration)
        self.startTime = first.startTime
        self.endTime = second.endTime
        self.durationSeconds = abs(first.startTime.timeIntervalSince(second.endTime))
        self.latitude = first.latitude      // It'd be better to average these
        self.longitude = first.longitude
    }

    public var description: String {
        return "\(style) @\(latitude), \(longitude), for \(durationSeconds) seconds, starting at \(startTime)"
    }
}
