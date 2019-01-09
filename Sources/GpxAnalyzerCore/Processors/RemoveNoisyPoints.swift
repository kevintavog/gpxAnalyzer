
struct RemoveNoisyPoints {
    static func process(_ vectors: [Vector]) -> [StatsPoint] {

        var filtered = [StatsPoint]()
        for idx in 0..<vectors.count {
            filtered += vectors[idx].points
        }

        return filtered
    }
}
