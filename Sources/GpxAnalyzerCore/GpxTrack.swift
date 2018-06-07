import Foundation

public struct GpxTrack : Codable {
    let segments: [GpxSegment]

    public init(segments: [GpxSegment]) {
        self.segments = segments
    }
}
