import Foundation

struct GpxSegment : Codable {
    let points: [GpxPoint]

    init(points: [GpxPoint]) {
        self.points = points
    }
}
