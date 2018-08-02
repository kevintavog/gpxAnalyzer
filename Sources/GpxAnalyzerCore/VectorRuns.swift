import Foundation

public struct Vector : Codable, CustomStringConvertible {
    public let points: [StatsPoint]
    public let bearing: Int
    public let distanceKm: Double
    public let seconds: Double

    init(points: [StatsPoint]) {
        self.points = points
        self.bearing = points.first!.gpx.bearing(to: points.last!.gpx)
        self.seconds = points.first!.gpx.seconds(between: points.last!.gpx)

        var distance = 0.0
        for i in 1..<points.count {
            distance += points[i - 1].gpx.distance(to: points[i].gpx)
        }
        self.distanceKm = distance
    }

    public var description: String {
        return "\(points.count) points, \(bearing) vector degrees (\(points[0].calculatedBearing) degrees), duration: \(seconds) seconds, distance: \(Int(distanceKm * 1000.0)) meters, starting at \(points[0].gpx.time)"
    }
}

struct VectorAnalyzer {
    static func calculate(run: StatsRun) -> [Vector] {
        var vectors = [Vector]()

        var droppedClosePointsCount = 0
        var droppedVectorCount = 0
        var vectorPoints = [StatsPoint]()
        for p in run.points {
            if vectorPoints.count == 0 {
                vectorPoints.append(p)
            } else {
                let distanceMeters = p.gpx.distance(to: vectorPoints.last!.gpx) * 1000
                if distanceMeters < 0.30 {
                    droppedClosePointsCount += 1
                    continue
                }

// let totalBearing = vectorPoints[0].gpx.bearing(to: p.gpx)
                let delta = p.calculatedBearing - vectorPoints.last!.calculatedBearing
                if abs(delta) > 30 {
                    if vectorPoints.count < 4 {
                        droppedVectorCount += 1
                    } else {
                        vectors.append(Vector(points: vectorPoints))
                    }
                    vectorPoints.removeAll()
                }
// print("bearing: \(p.calculatedBearing), delta: \(delta) @ \(p.gpx.time)")
                vectorPoints.append(p)
            }
        }

print("\(vectors.count) vectors, dropped \(droppedVectorCount) small vectors and \(droppedClosePointsCount) points close together")
var lastVector: Vector?
for v in vectors {
    var diff = 0
    if let last = lastVector {
        diff = abs(v.bearing - last.bearing)
    }
    lastVector = v
    print("  \(v.bearing), diff: \(diff) @ \(v.points[0].gpx.time)")
}
        return vectors
    }
}