import Foundation

class StatsPoint : Codable, CustomStringConvertible {
    let gpx: GpxPoint

    let kilometersFromLast: Double
    let kilometersIntoRun: Double
    let secondsIntoRun: Double
    var smoothedSpeed: Double = 0.0
    var speedTypes: [SpeedType] = [SpeedType]()


    var description: String {
        return "distance: \(kilometersIntoRun), time: \(secondsIntoRun), gpx: \(gpx);"
    }

    init(gpx: GpxPoint, kilometersIntoRun: Double, secondsIntoRun: Double, kilometersFromLast: Double) {
        self.gpx = gpx

        self.kilometersIntoRun = kilometersIntoRun
        self.secondsIntoRun = secondsIntoRun
        self.kilometersFromLast = kilometersFromLast
    }
}
