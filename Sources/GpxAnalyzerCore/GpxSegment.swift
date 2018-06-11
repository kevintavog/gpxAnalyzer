import Foundation

public struct GpxSegment : Codable {
    public let points: [GpxPoint]

    public init(points: [GpxPoint]) {
        self.points = points
    }
}
