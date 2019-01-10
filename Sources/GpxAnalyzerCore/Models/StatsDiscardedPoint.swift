import Foundation

public enum DiscardedReason: String, Codable {
    case poorDop = "poorDop"
    case badFix = "badFix"
}

public class StatsDiscardedPoint : Codable {
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
