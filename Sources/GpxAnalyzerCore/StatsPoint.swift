import Foundation

public class StatsPoint : Codable, CustomStringConvertible {
    public let gpx: GpxPoint

    public let kilometersFromLast: Double
    public let kilometersIntoRun: Double
    public let secondsIntoRun: Double
    public var smoothedSpeedKmH: Double = 0.0
    public var speedTypes: [SpeedType] = [SpeedType]()


    public var description: String {
        return "distance: \(kilometersIntoRun), time: \(secondsIntoRun), gpx: \(gpx);"
    }

    init(gpx: GpxPoint, kilometersIntoRun: Double, secondsIntoRun: Double, kilometersFromLast: Double) {
        self.gpx = gpx

        self.kilometersIntoRun = kilometersIntoRun
        self.secondsIntoRun = secondsIntoRun
        self.kilometersFromLast = kilometersFromLast
    }
}
