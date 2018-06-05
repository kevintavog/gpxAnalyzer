import Foundation

class StatsTrack : Codable, CustomStringConvertible {
    let runs: [StatsRun]
    let stops: [StatsStop]
    let discardedPoints: [StatsDiscardedPoint]

    let kilometers: Double
    let seconds: Double
    let averageSpeed: Double
    let minLat: Double
    let minLon: Double
    let maxLat: Double
    let maxLon: Double

    var description: String {
        return "\(Int(kilometers * 1000)) meters in \(seconds) seconds, \(averageSpeed) km/h on average"
    }

    init(runs: [StatsRun], stops: [StatsStop], discardedPoints: [StatsDiscardedPoint]) {
        self.runs = runs
        self.stops = stops
        self.discardedPoints = discardedPoints

        self.kilometers = runs.reduce(0.0, { $0 + $1.kilometers })
        self.seconds = runs.reduce(0.0, { $0 + $1.seconds })
        self.averageSpeed = kilometers / (seconds / 3600.0)

        var minimumLat = 180.0, minimumLon = 180.0
        var maximumLat = 0.0, maximumLon = -180.0

        for r in runs {
            minimumLat = min(minimumLat, r.minLat)
            minimumLon = min(minimumLon, r.minLon)
            maximumLat = max(maximumLat, r.maxLat)
            maximumLon = max(maximumLon, r.maxLon)
        }

        self.minLat = minimumLat
        self.minLon = minimumLon
        self.maxLat = maximumLat
        self.maxLon = maximumLon
     }
}
