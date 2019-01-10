import Foundation

public struct GpxTrack : Codable {
    public let segments: [GpxSegment]

    public init(segments: [GpxSegment]) {
        self.segments = segments
    }
}
