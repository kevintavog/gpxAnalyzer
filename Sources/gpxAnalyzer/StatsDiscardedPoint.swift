import Foundation

enum DiscardedReason: String, Codable {
    case poorDop = "poorDop"
    case badFix = "badFix"
}

class StatsDiscardedPoint : Codable {
    let gpx: GpxPoint
    let reason: DiscardedReason

    init(gpx: GpxPoint) {
        self.gpx = gpx
        if !gpx.hasGoodGPSFix {
            self.reason = DiscardedReason.badFix
        } else {
            self.reason = DiscardedReason.poorDop
        }
    }
}
