import Foundation

enum PointCategory: String, Codable {
    case poorQuality = "poorQuality"
    case moving = "moving"
    case stopped = "stopped"
}

struct PointInfo {
    let gpx: GpxPoint
    let category: PointCategory

    init(_ gpx: GpxPoint, _ category: PointCategory) {
        self.gpx = gpx
        self.category = category
    }
}
