import Foundation

public class StatsGpx : Codable {
    public let schemaVersion = 1
    public let tracks: [StatsTrack]

    public let minLat: Double
    public let minLon: Double
    public let maxLat: Double
    public let maxLon: Double

    init(tracks: [StatsTrack]) {
        self.tracks = tracks

        var minimumLat = 180.0, minimumLon = 180.0
        var maximumLat = 0.0, maximumLon = -180.0

        for t in tracks {
            minimumLat = min(minimumLat, t.minLat)
            minimumLon = min(minimumLon, t.minLon)
            maximumLat = max(maximumLat, t.maxLat)
            maximumLon = max(maximumLon, t.maxLon)
        }

        self.minLat = minimumLat
        self.minLon = minimumLon
        self.maxLat = maximumLat
        self.maxLon = maximumLon
     }
}
