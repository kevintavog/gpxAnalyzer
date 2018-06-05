import Foundation

struct GpxTrack : Codable {
    let segments: [GpxSegment]

    init(segments: [GpxSegment]) {
        self.segments = segments
    }
}
