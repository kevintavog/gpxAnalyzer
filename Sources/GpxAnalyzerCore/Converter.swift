
struct Converter {
    static public func metersPerSecondToKilometersPerHour(metersSecond: Double) -> Double {
        return metersSecond * (3600.0 / 1000.0)
    }
}
