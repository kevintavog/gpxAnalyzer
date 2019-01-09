
struct CategorizePoints {
    static func process(_ points: [GpxPoint]) -> [StatsPoint] {
        var category = [StatsPoint]()
        if points.count < 1 {
            return category
        }

        var lastBadIndex: Int? = nil
        var idx = 0
        while idx < points.count {
            let p = points[idx]
            var ptCat = StatsPointCategory.poorQuality
            var avgGpxSpeed:Double? = nil
            var calculatedSpeed:Double? = nil
            var bearing: Int = -1
            if p.hasGoodDOP && p.hasGoodGPSFix {
                (avgGpxSpeed, calculatedSpeed) = recentAverageSpeeds(points, idx, 5)
                if idx > 0 {
                    bearing = points[idx - 1].bearing(to: p)
                    if idx == 1 {
                        category[0].bearing = bearing
                    }
                }
                if let avgGpxSpeed = avgGpxSpeed, let calculatedSpeed = calculatedSpeed {
                    ptCat = avgGpxSpeed >= GpxAnalyzer.minimumMovingAverageSpeedMetersSecond 
                            || calculatedSpeed >= GpxAnalyzer.minimumMovingAverageSpeedMetersSecond
                        ? .moving : .stopped
                } else {
                    ptCat = .moving
                }

                if idx > 0 {
                    let seconds = p.seconds(between: points[idx - 1])
                    let distance = p.distance(to: points[idx - 1])
                    let calculatedSpeed = p.speed(seconds: seconds, distance: distance)
                    let pointKmH = Converter.metersPerSecondToKilometersPerHour(metersSecond: p.speed)

                    if (calculatedSpeed > 10.0 || pointKmH > 10.0) && distance > 0.040 {
                        // 'max' overrides 0.0, which otherwise causes a divide by zero
                        let lower = max(0.1, min(calculatedSpeed, pointKmH))
                        let higher = max(calculatedSpeed, pointKmH)
                        let ratio = higher / lower
                        if ratio > 20.0 {
// print("speed: \(pointKmH) [\(calculatedSpeed)] -- ratio: \(ratio), seconds: \(Int(seconds)), distance: \(distance * 1000.0): \(p.time)")
                            ptCat = StatsPointCategory.poorQuality
                            if ratio > 20 && distance > 20 {
                                lastBadIndex = findLastBad(points, idx - 1, idx)
                            }
                        }
                    }
                }

            } else {
                ptCat = .poorQuality
            }

            // category.append(PointInfo(p, ptCat, bearing, avgGpxSpeed, calculatedSpeed))
            category.append(StatsPoint(p, ptCat, bearing, avgGpxSpeed, calculatedSpeed))
            idx += 1
            if let badIndex = lastBadIndex, badIndex > idx {
                for updateIndex in idx...badIndex {
                    category.append(StatsPoint(points[updateIndex], .poorQuality, -1, nil, nil))
                }
                idx = badIndex + 1
            }
        }

        return category
    }

    static func findLastBad(_ points: [GpxPoint], _ lastGoodIndex: Int, _ firstBadIndex: Int) -> Int {
        let lastGood = points[lastGoodIndex]
        let end = min(firstBadIndex + 40, points.count - 1)
        for index in firstBadIndex...end {
            let p = points[index]
            let distance = p.distance(to: lastGood)
            if distance < 20.0 {
                return index - 1
            }
        }

        return firstBadIndex
    }

    static func recentAverageSpeeds(_ points: [GpxPoint], _ start: Int, _ seconds: Int) -> (Double?, Double?) {
        var sumGpxSpeed = 0.0
        var index = start
        var secondsDiff = 0
        repeat {
            secondsDiff = Int(points[start].seconds(between: points[index]))
            sumGpxSpeed += points[index].speed
            index -= 1
        } while (index >= 0 && secondsDiff < seconds)

        if secondsDiff >= seconds {
            let calculatedSpeed = Converter.kilometersPerHourToMetersPerSecond(kmh: points[start].speed(between: points[index + 1]))
            return (sumGpxSpeed / Double(seconds), calculatedSpeed / Double(seconds))
        }

        return (nil, nil)
    }
}