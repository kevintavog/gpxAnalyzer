
struct Converter {
    static public func metersPerSecondToKilometersPerHour(metersSecond: Double) -> Double {
        return metersSecond * (3600.0 / 1000.0)
    }

    static public func kilometersPerHourToMetersPerSecond(kmh: Double) -> Double {
        return kmh * (1000.0 / 3600.0)
    }
}
