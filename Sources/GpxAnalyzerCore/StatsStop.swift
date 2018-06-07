import Foundation

public enum StatsStopStyle: String, Codable {
    case paused = "paused"
    case stopped = "stopped"
}


public class StatsStop : Codable, CustomStringConvertible {
    let style: StatsStopStyle
    let latitude: Double
    let longitude: Double
    let startTime: Date
    let endTime: Date
    let durationSeconds: Double

    init(style: StatsStopStyle, points: [GpxPoint]) {
        self.style = style
        self.startTime = points[0].time
        self.endTime = points[points.count - 1].time
        self.durationSeconds = points[0].seconds(between: points[points.count - 1])

        // Calculate a center point
        self.latitude = points.reduce(0.0, { $0 + $1.latitude }) / Double(points.count)
        self.longitude = points.reduce(0.0, { $0 + $1.longitude }) / Double(points.count)
    }

    public var description: String {
        return "\(style) @\(latitude), \(longitude), for \(durationSeconds) seconds, starting at \(startTime)"
    }
}
