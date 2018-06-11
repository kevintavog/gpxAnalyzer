import Foundation
import SwiftyXML

public struct GpxPoint : Codable, CustomStringConvertible {
    public let latitude: Double
    public let longitude: Double
    public let elevation: Double
    public let time: Date
    public let course: Double

    // Meters per second
    public let speed: Double
    public let speedKmH: Double

    public let fix: String?
    public let hdop: Double?
    public let pdop: Double?
    public let vdop: Double?       // Vertical - it's ignored, but available for display in the UI

    static private var dateTimeFormatter: DateFormatter?


    public init(xml: XML) {
        if GpxPoint.dateTimeFormatter == nil {
            GpxPoint.dateTimeFormatter = DateFormatter()
            GpxPoint.dateTimeFormatter?.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            GpxPoint.dateTimeFormatter?.timeZone = TimeZone(secondsFromGMT: 0)
        }

        self.latitude = xml["@lat"].doubleValue
        self.longitude = xml["@lon"].doubleValue
        self.elevation = xml["ele"].doubleValue
        self.time = GpxPoint.dateTimeFormatter!.date(from: xml["time"].stringValue)!
        self.course = xml["course"].doubleValue
        self.speed = xml["speed"].doubleValue

        self.speedKmH = self.speed * (3600.0 / 1000.0)

        self.fix = xml["fix"].string
        self.hdop = xml["hdop"].double
        self.vdop = xml["vdop"].double
        self.pdop = xml["pdop"].double
    }

    var hasGoodGPSFix: Bool {
        return !(fix == "2d")
    }

    var hasGoodDOP: Bool {
        return (hdop ?? 0.0) < 2.5 && (pdop ?? 0) < 2.5
    }

    // Use the small distance calculation (Pythagorus' theorem)
    // See the 'Equirectangular approximation' section of http://www.movable-type.co.uk/scripts/latlong.html
    // The distance returned is in kilometers
    public func distance(to: GpxPoint) -> Double {
        let rLat1 = self.latitude * Double.pi / 180
        let rLon1 = self.longitude * Double.pi / 180
        let rLat2 = to.latitude * Double.pi / 180
        let rLon2 = to.longitude * Double.pi / 180

        let x = (rLon2 - rLon1) * cos((rLat1 + rLat2) / 2)
        let y = rLat2 - rLat1
        return sqrt((x * x) + (y * y)) * 6371.3 // radius of earth in kilometers
    }

    // Number of seconds between two points, independent of which is earlier
    public func seconds(between: GpxPoint) -> Double {
        return abs(self.time.timeIntervalSince(between.time))
    }

    // Return the speed, in kilometers / hour, between two points
    public func speed(between: GpxPoint) -> Double {
        return speed(between: between, distance: distance(to: between))
    }

    public func speed(between: GpxPoint, distance: Double) -> Double {
        return speed(seconds: seconds(between: between), distance: distance)
    }

    public func speed(seconds: Double, distance: Double) -> Double {
        let time = (seconds / 3600.0)
        if time < 0.000001 {
            return 0.0
        }
        return distance / time
    }

    public var description: String {
        return "\(latitude), \(longitude), speed: \(speed), @\(time)"
    }

    var dms: String {
        let latitudeNorthOrSouth = latitude < 0 ? "S" : "N"
        let longitudeEastOrWest = longitude < 0 ? "W" : "E"
        return "\(toDms(latitude)) \(latitudeNorthOrSouth), \(toDms(longitude)) \(longitudeEastOrWest)"
    }

    fileprivate func toDms(_ geo: Double) -> String {
        var g = geo
        if (g < 0.0) {
            g *= -1.0
        }

        let degrees = Int(g)
        let minutesDouble = (g - Double(degrees)) * 60.0
        let minutesInt = Int(minutesDouble)
        let seconds = (minutesDouble - Double(minutesInt)) * 60.0

        return String(format: "%.2d° %.2d' %.2f\"", degrees, minutesInt, seconds)
    }

}
