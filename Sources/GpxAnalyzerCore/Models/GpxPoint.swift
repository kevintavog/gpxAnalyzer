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
    public let vdop: Double?       // Vertical - it's ignored when analyzing, but available for display in the UI

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
        return (hdop ?? 0.0) <= 3.0 && (pdop ?? 0) <= 3.0
    }

    // The distance returned is in kilometers
    public func distance(to: GpxPoint) -> Double {
        return Geo.distance(lat1: self.latitude, lon1: self.longitude, lat2: to.latitude, lon2: to.longitude)
    }

    // The bearing is returned in degrees
    public func bearing(to: GpxPoint) -> Int {
        return Geo.bearing(lat1: self.latitude, lon1: self.longitude, lat2: to.latitude, lon2: to.longitude)
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
        return Converter.speedKph(seconds: seconds, kilometers: distance)
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
