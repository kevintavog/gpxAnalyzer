import Foundation

// From https://www.bbc.com/education/guides/zq4mfcw/revision
// Average speeds   m/s     km/h        m/h
//      --          0.417   1.5         0.93
//      Walking     1.5     5.4         3.4
//      Running     5       18          11
//      Cycling     7       25          15
//      Car         13-30   46-108      29-67
//      Train       56      201         125
//      Plane       250     900         560
public enum TransportationType: String, Codable {
    case unknown = "unknown"
    case foot = "foot"
    case bicycle = "bicycle"
    case car = "car"
    case train = "train"
    case plane = "plane"
}

public struct SpeedType: Codable {
    public let probability: Double
    public let transportation: TransportationType

    init(probability: Double, transportation: TransportationType) {
        self.probability = probability
        self.transportation = transportation
    }
}

// Speeds, in kilometers per hour, of different transportation types. Given a single speed, a table of SpeedProfile instances
// is used to determine up to the two most likely transportation types.
// Probabilities are 1.0 for included in the nominal range. Outside of that range, but within the absolute range, the
// probability is a linear value starting from 0.10
struct SpeedProfile {
    let absoluteMinimum: Double
    let nominalMinimum: Double
    let nominalMaximum: Double
    let absoluteMaximum: Double
    let transportation: TransportationType
}

public class TransportationAnalyzer {

    static private let speedProfiles = [
        SpeedProfile(absoluteMinimum: 0.0, nominalMinimum: 1.0, nominalMaximum: 6.4, absoluteMaximum: 7.4, transportation: .foot),
        SpeedProfile(absoluteMinimum: 6.4, nominalMinimum: 12.0, nominalMaximum: 34.0, absoluteMaximum: 41.0, transportation: .bicycle),
        SpeedProfile(absoluteMinimum: 16.0, nominalMinimum: 25.0, nominalMaximum: 128.0, absoluteMaximum: 160.0, transportation: .car),
        SpeedProfile(absoluteMinimum: 90.0, nominalMinimum: 100.0, nominalMaximum: 200.0, absoluteMaximum: 300.0, transportation: .train),
        SpeedProfile(absoluteMinimum: 100.0, nominalMinimum: 160.0, nominalMaximum: 800.0, absoluteMaximum: 1000.0, transportation: .plane)]

    static public func calculate(gpx: GpxPoint) -> [SpeedType] {
        return TransportationAnalyzer.calculate(speedKmh: gpx.speedKmH)
    }

    static public func calculate(point: StatsPoint) -> [SpeedType] {
        return TransportationAnalyzer.calculate(speedKmh: point.smoothedSpeedKmH)
    }

    static public func calculate(speedKmh: Double) -> [SpeedType] {
        var speedTypes = [SpeedType]()
        for p in TransportationAnalyzer.speedProfiles {
            var probability: Double? = nil
            if speedKmh >= p.nominalMinimum && speedKmh <= p.nominalMaximum {
                probability = 1.0
            } else if speedKmh >= p.absoluteMinimum && speedKmh < p.nominalMinimum {
                probability = TransportationAnalyzer.probability(speedKmh, p.absoluteMinimum, p.nominalMinimum)
            } else if speedKmh > p.nominalMaximum && speedKmh <= p.absoluteMaximum {
                probability = TransportationAnalyzer.probability(speedKmh, p.absoluteMaximum, p.nominalMaximum)
            }

            if let probability = probability, probability > 0.0 {
                speedTypes.append(SpeedType(probability: probability, transportation: p.transportation))                
            }
        }

        if speedTypes.count < 1 {
            return [SpeedType(probability: 1.0, transportation: .unknown)]
        }
        return Array(speedTypes.sorted(by: { $0.probability > $1.probability}).prefix(2))
    }

    static private func probability(_ value: Double, _ absolute: Double, _ nominal: Double) -> Double {
        return max(0.01, (value - absolute) / (nominal - absolute))
    }

    private func guessTransportation(_ run: StatsRun) -> TransportationType {
        if run.style == .track {
            let averageSpeed = run.kilometers / (run.seconds / 3600.0)
            switch averageSpeed {
                case 0..<12:
                    return .foot
                case 12..<35:
                    return .bicycle
                case 35..<128:
                    return .car
                case 128..<250:
                    return .train
                case 250..<1000:
                    return .plane
                default:
                    return .unknown
            }
        }
        return TransportationType.unknown
    }
}
