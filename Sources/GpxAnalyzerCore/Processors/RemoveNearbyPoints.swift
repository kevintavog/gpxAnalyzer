
struct RemoveNearbyPoints {
    static func process(_ points: [GpxPoint]) -> [GpxPoint] {
        var filtered = [GpxPoint]()
        for p in points {
            if filtered.count == 0 {
                filtered.append(p)
            } else {
                let distanceMeters = p.distance(to: filtered.last!) * 1000
                if distanceMeters >= 1 {
                    filtered.append(p)
                }
            }
        }
print("removed \(points.count - filtered.count) nearby points")
        return filtered
    }
}
