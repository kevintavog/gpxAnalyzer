import Foundation

public enum StatsPointCategory: String, Codable {
    case poorQuality = "poorQuality"
    case moving = "moving"
    case stopped = "stopped"
}

public class StatsPoint : Codable, CustomStringConvertible {
    public let gpx: GpxPoint

    public var averageGpxSpeed: Double?
    public var calculatedSpeed: Double?
    public var bearing: Int
    public var kilometersFromLast: Double?
    public var kilometersIntoRun: Double?
    public var secondsIntoRun: Double?
    public var smoothedSpeedKmH: Double = 0.0
    public var category: StatsPointCategory?
    public var speedTypes: [SpeedType] = [SpeedType]()


    public var description: String {
        return "distance: \(String(describing: kilometersIntoRun)), time: \(String(describing: secondsIntoRun)), bearing: \(bearing), gpx: \(gpx);"
    }

    init(_ gpx: GpxPoint, _ category: StatsPointCategory, _ bearing: Int, _ averageGpxSpeed: Double?, _ calculatedSpeed: Double?) {
        self.gpx = gpx
        self.category = category
        self.bearing = bearing
        self.averageGpxSpeed = averageGpxSpeed
        self.calculatedSpeed = calculatedSpeed
    }

    init(gpx: GpxPoint, bearing: Int, kilometersIntoRun: Double, secondsIntoRun: Double, kilometersFromLast: Double) {
        self.gpx = gpx
        self.bearing = bearing
        self.kilometersIntoRun = kilometersIntoRun
        self.secondsIntoRun = secondsIntoRun
        self.kilometersFromLast = kilometersFromLast
    }
}
