import Foundation

public struct GpxSegment : Codable {
    let points: [GpxPoint]

    public init(points: [GpxPoint]) {
        self.points = points
    }
}
