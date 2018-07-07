import Foundation

public class Geo {

    static let radiusEarthKm = 6371.3

    // Use the small distance calculation (Pythagorus' theorem)
    // See the 'Equirectangular approximation' section of http://www.movable-type.co.uk/scripts/latlong.html
    // The distance returned is in kilometers
    static public func distance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let rLat1 = lat1 * Double.pi / 180
        let rLon1 = lon1 * Double.pi / 180
        let rLat2 = lat2 * Double.pi / 180
        let rLon2 = lon2 * Double.pi / 180

        let x = (rLon2 - rLon1) * cos((rLat1 + rLat2) / 2)
        let y = rLat2 - rLat1
        return sqrt((x * x) + (y * y)) * radiusEarthKm // radius of earth in kilometers
    }
}