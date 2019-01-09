import Foundation

public struct Vector : Codable, CustomStringConvertible {
    public let points: [StatsPoint]
    public let bearing: Int
    public let distanceKm: Double
    public let seconds: Double
    public let speedKph: Double

    public var removed: Bool = false
    public var score: Int = 1000
    public var prevScore: Int = 1000
    public var curScore: Int = 1000
    public var nextScore: Int = 1000

    init(points: [StatsPoint]) {
        self.points = points
        self.bearing = points.first!.gpx.bearing(to: points.last!.gpx)
        self.seconds = points.first!.gpx.seconds(between: points.last!.gpx)

        var distance = 0.0
        for i in 1..<points.count {
            distance += points[i - 1].gpx.distance(to: points[i].gpx)
        }
        self.distanceKm = distance
        self.speedKph = Converter.speedKph(seconds: seconds, kilometers: distanceKm)
    }

    public var description: String {
        return "\(points.count) points, \(bearing) vector degrees, duration: \(seconds) seconds, distance: \(Int(distanceKm * 1000.0)) meters, starting at \(points[0].gpx.time)"
    }
}

struct VectorAnalyzer {

    static let maxAngle = 45
    static let maxSeconds = 10.0
    static let maxMeters = 10
    static let removeVectorScoreThreshold = 150

    static func calculate(points: [StatsPoint]) -> [Vector] {
        var vectors = [Vector]()

        var vectorPoints = [StatsPoint]()
        for pi in points {
            if vectorPoints.count > 0 {
                let delta = Geo.bearingDelta(pi.bearing, vectorPoints.last!.bearing)
                if delta > VectorAnalyzer.maxAngle {
                    if vectorPoints.count >= 2 {
                        vectors.append(Vector(points: vectorPoints))
                    }
                    vectorPoints.removeAll()
                }
            }
            vectorPoints.append(pi)
        }

        if vectorPoints.count > 0 {
            vectors.append(Vector(points: vectorPoints))
        }

        // Check the vector bearing - if consecutive ones are close, combine them
        var combinedVectors = [Vector]()
        combinedVectors.append(vectors[0])
        for idx in 1..<vectors.count {
            let cur = vectors[idx]
            let prev = combinedVectors.last!
            let deltaBearing = Geo.bearingDelta(prev.bearing, cur.bearing)
            let deltaSeconds = prev.points.last!.gpx.seconds(between: cur.points.first!.gpx)
            let deltaMeters = Int(prev.points.last!.gpx.distance(to: cur.points.first!.gpx) * 1000)
            if deltaBearing < VectorAnalyzer.maxAngle && deltaSeconds < VectorAnalyzer.maxSeconds && deltaMeters < VectorAnalyzer.maxMeters {
                let combination = Vector(points: prev.points + cur.points)
                combinedVectors.removeLast()
                combinedVectors.append(combination)
            } else {
                combinedVectors.append(cur)
            }
        }

        // Reduce the vectors - those that don't line up with the next
        var removedVectors = false
        repeat {
            removedVectors = false
            var retainedVectors = [Vector]()
            for idx in 1..<(combinedVectors.count - 1) {
                var cur = combinedVectors[idx]
                let prev = combinedVectors[idx - 1]
                let next = combinedVectors[idx + 1]
                (cur.score, cur.prevScore, cur.curScore, cur.nextScore) = VectorAnalyzer.score(prev: prev, cur: cur, next: next)

                // let remove = deltaBearing > 45 && (deltaSeconds > 5.0 || deltaMeters > 10)
//                 if remove {
//                     removedVectors = true
// print("vector delta: \(remove ? "REMOVE" : "keep") \(deltaBearing) degrees, \(deltaSeconds) seconds and \(deltaMeters) meters @\(cur.points.first!.gpx.time)")
//                 } else {
                    retainedVectors.append(cur)
                // }
            }

            // Special handling for the first and last - need to ensure they're worth including
            retainedVectors.append(combinedVectors.last!)
            retainedVectors.insert(combinedVectors.first!, at: 0)


            combinedVectors = retainedVectors
        } while removedVectors

        // Remove the vectors that are unsatisfactory (too short, etc)
        var filteredVectors = [Vector]()
        for v in combinedVectors {
            if v.distanceKm > 0.001 {
                filteredVectors.append(v)
            }
        }

print("Reduced \(vectors.count) to \(combinedVectors.count) and filtered to \(filteredVectors.count)")
        return filteredVectors
    }

    static func score(prev: Vector, cur: Vector, next: Vector) -> (Int, Int, Int, Int) {
        let prevDeltaBearing = Geo.bearingDelta(prev.bearing, cur.bearing)
        let prevDeltaSeconds = Int(prev.points.last!.gpx.seconds(between: cur.points.first!.gpx))
        let prevDeltaMeters = Int(prev.points.last!.gpx.distance(to: cur.points.first!.gpx) * 1000)
        let prevSpeedKph = Int(Converter.speedKph(seconds: prevDeltaSeconds, kilometers: prev.points.last!.gpx.distance(to: cur.points.first!.gpx)))
        let nextDeltaBearing = Geo.bearingDelta(cur.bearing, next.bearing)
        let nextDeltaSeconds = Int(cur.points.last!.gpx.seconds(between: next.points.first!.gpx))
        let nextDeltaMeters = Int(cur.points.last!.gpx.distance(to: next.points.first!.gpx) * 1000)
        let nextSpeedKph = Int(Converter.speedKph(seconds: nextDeltaSeconds, kilometers: cur.points.last!.gpx.distance(to: next.points.first!.gpx)))

        var scorePrev = max(Double(prevDeltaBearing - 60) / 60.0, 0.0) * 4.0
        scorePrev += max(5.0 * Double(prevDeltaSeconds - 3) / 3.0, 0.0)
        scorePrev += max(5.0 * Double(prevDeltaMeters - 3) / 3.0, 0.0)

        var scoreNext = max(Double(nextDeltaBearing - 60) / 60.0, 0.0) * 4.0
        scoreNext += max(5.0 * Double(nextDeltaSeconds - 3) / 3.0, 0.0)
        scoreNext += max(5.0 * Double(nextDeltaMeters - 3) / 3.0, 0.0)

        var scoreCur = cur.seconds / Double(cur.points.count) * 2
        scoreCur += cur.points.count < 4 ? Double((5 - cur.points.count) * 5) : 0

        let score = Int(10.0 * (scorePrev + scoreCur + scoreNext))

print("score: \(score) - [\(Int(scorePrev * 10)) - \(Int(scoreCur * 10)) - \(Int(scoreNext * 10))]; " +
    "[prev: \(prevDeltaBearing) degrees, \(prevDeltaMeters) meters, \(prevDeltaSeconds) seconds, \(prevSpeedKph) kph;] " +
    "[next: \(nextDeltaBearing), \(nextDeltaMeters) meters, \(nextDeltaSeconds) seconds, \(nextSpeedKph) kph;] " +
    "[\(cur.points.count) points, \(Int(cur.distanceKm * 1000.0)) meters, " +
    "\(Int(cur.speedKph)) kph, \(Int(cur.seconds)) seconds @ \(cur.points.first!.gpx.time)]")

        return (score, Int(10.0 * scorePrev), Int(10.0 * scoreCur), Int(10.0 * scoreNext))
    }
}
