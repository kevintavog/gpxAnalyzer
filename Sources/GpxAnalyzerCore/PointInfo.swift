import Foundation

enum PointCategory: String, Codable {
    case poorQuality = "poorQuality"
    case moving = "moving"
    case stopped = "stopped"
}

struct PointInfo {
    let gpx: GpxPoint
    let averageSpeed: Double?
    let category: PointCategory

    init(_ gpx: GpxPoint, _ averageSpeed: Double?, _ category: PointCategory) {
        self.gpx = gpx
        self.averageSpeed = averageSpeed
        self.category = category
    }
}
