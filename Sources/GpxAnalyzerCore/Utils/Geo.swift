import Foundation

public struct GeoRectangle {
    let minLat: Double
    let minLon: Double
    let maxLat: Double
    let maxLon: Double

    init(minLat: Double, minLon: Double, maxLat: Double, maxLon: Double) {
        self.minLat = minLat
        self.minLon = minLon
        self.maxLat = maxLat
        self.maxLon = maxLon
    }
}

public class Geo {

    static let radiusEarthKm = 6371.3
    static let oneDegreeLatitudeMeters = 111111.0

    static public func bearingDelta(_ alpha: Int, _ beta: Int) -> Int {
        let phi = abs(beta - alpha) % 360
        return phi > 180 ? 360 - phi : phi
    }


    // Use the small distance calculation (Pythagorus' theorem)
    // See the 'Equirectangular approximation' section of http://www.movable-type.co.uk/scripts/latlong.html
    // The distance returned is in kilometers
    static public func distance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let rLat1 = Geo.toRadians(degrees: lat1)
        let rLon1 = Geo.toRadians(degrees: lon1)
        let rLat2 = Geo.toRadians(degrees: lat2)
        let rLon2 = Geo.toRadians(degrees: lon2)

        let x = (rLon2 - rLon1) * cos((rLat1 + rLat2) / 2)
        let y = rLat2 - rLat1
        return sqrt((x * x) + (y * y)) * radiusEarthKm // radius of earth in kilometers
    }

    // Returns the bearing in degrees: 0-359, with 0 as north and 90 as east
    // From https://www.movable-type.co.uk/scripts/latlong.html
    //      https://github.com/chrisveness/geodesy/blob/master/latlon-spherical.js
    static public func bearing(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Int {
        let rLat1 = Geo.toRadians(degrees: lat1)
        let rLat2 = Geo.toRadians(degrees: lat2)
        let rLonDelta = Geo.toRadians(degrees: lon2 - lon1)

        let y = sin(rLonDelta) * cos(rLat2)
        let x = (cos(rLat1) * sin(rLat2)) - (sin(rLat1) * cos(rLat2) * cos(rLonDelta))

        return (Int(Geo.toDegrees(radians: atan2(y, x))) + 360) % 360
    }

    // Returns true if the two rectangles are with the given distance, including overlaps. False otherwise.
    static public func within(meters: Double, first: GeoRectangle, second: GeoRectangle) -> Bool {
        var latOffset: Double = 0.0
        var lonOffset: Double = 0.0
        (latOffset, lonOffset) = Geo.meterOffsetAt(distanceMeters: meters / 2.0, latitude: first.minLat, longitude: first.minLon)

        // Does first intersect with second, using the lat/lon offsets?
        if (first.minLat - latOffset) < second.maxLat
                && (first.maxLat + latOffset) > second.minLat
                && (first.maxLon + lonOffset) > second.minLon
                && (first.minLon - lonOffset) < second.maxLon {
            return true
        }
        return false
    }

    static public func meterOffsetAt(distanceMeters: Double, latitude: Double, longitude: Double) -> (Double, Double) {
        // From https://gis.stackexchange.com/questions/2951/algorithm-for-offsetting-a-latitude-longitude-by-some-amount-of-meters
        // 111,111 meters is approximately 1 degree latitude
        // 111111 * cos (latitude) is approximately 1 degree longitude
        let latOffset = distanceMeters / oneDegreeLatitudeMeters
        let lonRadians = longitude * Double.pi / 180
        let lonOffset = distanceMeters / (oneDegreeLatitudeMeters * cos(lonRadians))
        return (latOffset, lonOffset)
    }

    static public func toRadians(degrees: Double) -> Double {
        return degrees * Double.pi / 180.0
    }

    static public func toDegrees(radians: Double) -> Double {
        return radians * 180.0 / Double.pi
    }
}
