import Foundation


// Keep in mind that the beginning of a track is highly suspect: if the device is warming up or coming
// out of a tunnel. Extra scrutiny is likely in order in for the beginning.

// From http://www.toptal.com/gis/adventures-in-gps-track-analytics-a-geospatial-primer
//  Possible implementation: https://github.com/tkrajina/gpxpy
// Calculate max speed: 
//      Remove the top 5% points by distance
//      Remove the top 5% points by speed
// Smoothing (same article), probably run multiple times:
//      points[n].latitude = points[n-1].latitude * 0.3 + points[n].latitude * .4 + points[n+1].latitude * .3
//      <optionally smooth data>
//      points[n].longitude = points[n-1].longitude * 0.3 + points[n].longitude * .4 + points[n+1].longitude * .3

// Deduce stop points:
// From https://medium.com/strava-engineering/the-global-heatmap-now-6x-hotter-23fc01d301de
//  Referenced from https://gis.stackexchange.com/questions/89451/how-to-calculate-stop-points-from-a-set-of-gps-tracklogs
// If the magnitude of the time averaged velocity of an activity stream gets too low at any point, subsequent points from 
// that activity are filtered until the activity breaches a specific radius in distance from the initial stopped point.

// Deduce activity:
//      Average speed: is either a specific activity, or one of a couple activities
//          Use max speed, or max relative speed (multiplier between average & max) to decide


public class GpxAnalyzer {
    static let weighted = [0.4, 0.2, 0.4]

    // Below 1-2 km/h, we're going to consider it highly likely the trace is at a stop point
    static let minimumMovingAverageSpeedMetersSecond = 0.417
    static let minimumStopDurationSeconds = 5 * 60.0

    var _runs = [StatsRun]()
    var _stops = [StatsStop]()
    var _discardedPoints = [StatsDiscardedPoint]()


    static public func generateStats(gpxTracks: [GpxTrack]) -> StatsGpx {

        let analyzer = GpxAnalyzer()
        var tracks = [StatsTrack]()
        for t in gpxTracks {
            for s in t.segments {
                tracks.append(contentsOf: analyzer.createTracks(s.points))
            }
        }

        return StatsGpx(tracks: analyzer.finalizeTracks(tracks))
    }

    private func finalizeTracks(_ input: [StatsTrack]) -> [StatsTrack] {
        var tracks = [StatsTrack]()
        for t in input {
            let runs = consolidateRuns(t.runs)
            let stops = consolidateStops(t.stops, runs)
            if runs.count > 0 || stops.count > 0 {
                tracks.append(StatsTrack(runs: runs, stops: stops, discardedPoints: t.discardedPoints))
            }
else {
    print("Removed track \(t)")
}
        }

        return tracks
    }

    private func consolidateStops(_ stops: [StatsStop], _ runs: [StatsRun]) -> [StatsStop] {
        var response = [StatsStop]()
        for idx in 1..<stops.count {
            let thisStop = stops[idx]
            let lastStop = response.last ?? stops[idx - 1]
            let diffSeconds = abs(thisStop.startTime.timeIntervalSince(lastStop.endTime))
            let intermediateRuns = findIntermediateRuns(runs, lastStop.endTime, thisStop.startTime)
            print("last stop ends @\(lastStop.endTime); \(diffSeconds) and next starts @\(thisStop.startTime), \(intermediateRuns)")

            if intermediateRuns.count == 0 {
                if response.count > 0 {
                    response.removeLast()
                }
                response.append(StatsStop(first: lastStop, second: thisStop))
            } else {
                if idx == 1 {
                    response.append(lastStop)
                }
                response.append(thisStop)
            }
        }

        return response
    }

    private func findIntermediateRuns(_ runs: [StatsRun], _ startTime: Date, _ endTime: Date) -> [StatsRun] {
        var matches = [StatsRun]()
        for r in runs {
            if r.points.first!.gpx.time > startTime && r.points.last!.gpx.time < endTime {
                matches.append(r)
            }
        }

        return matches
    }

    private func consolidateRuns(_ input: [StatsRun]) -> [StatsRun] {
        var firstRuns = [StatsRun]()

        // First pass - append track runs when it makes sense
        var prevRun = input[0]
        firstRuns.append(prevRun)
        for index in 1..<input.count {
            let r = input[index]
            let seconds = r.points.first!.gpx.seconds(between: prevRun.points.last!.gpx)
            if r.style == prevRun.style && seconds < 5 {
                for p in r.points {
                    prevRun.add(gpx: p.gpx)
                }
                continue
            }

            firstRuns.append(r)
            prevRun = r
        }

        // Second pass - remove runs that are really short
        var runs = [StatsRun]()
        for r in firstRuns {
            if r.style == RunStyle.track {
                if r.seconds >= 20.0 && r.kilometers >= 0.020 {
                    runs.append(r)
                }
            } else {
                runs.append(r)
            }
        }

        if runs.count > 0 && runs.last!.style != RunStyle.track {
            print("Removing last non-track run: \(runs.last!)")
            runs.removeLast()
        }

        // Third pass - update the track offsets for each run
        if runs.count > 0 {
            let trackStart = runs[0].points[0].gpx
            var trackOffsetKilometers = 0.0
            for r in runs {
                r.trackOffsetSeconds = trackStart.seconds(between: r.points[0].gpx)
                r.trackOffsetKilometers = trackOffsetKilometers
                trackOffsetKilometers += r.kilometers
                assignTransporation(r)
            }
        }

        return runs
    }

    private func assignTransporation(_ run: StatsRun) {
        var speeds = [TransportationType: Double]()
        var prob100 = [TransportationType: Int]()
        var lastFewPoints = [StatsPoint]()
        for p in run.points {
            if lastFewPoints.count > 3 {
                lastFewPoints.removeFirst()
            }
            lastFewPoints.append(p)
            p.smoothedSpeedKmH =  Converter.metersPerSecondToKilometersPerHour(metersSecond: GpxAnalyzer.recentAverageSpeed(lastFewPoints))

            p.speedTypes = TransportationAnalyzer.calculate(gpx: p.gpx)
            for st in p.speedTypes {
                speeds[st.transportation, default: 0.0] += st.probability
                if st.probability >= 1.0 {
                    prob100[st.transportation, default: 0] += 1
                }
            }
        }

        run.speedTypes = Array(speeds.map { (key, value) in
            return SpeedType(probability: value / Double(run.points.count), transportation: key)
        }.sorted(by: { $0.probability > $1.probability}).prefix(3))
// print("100: \(prob100) -- \(speeds)")
    }

    private func createTracks(_ points: [GpxPoint]) -> [StatsTrack] {

        // The first pass will mark each point as:
        //  a) Poor quality (DOP or Fix)
        //  b) Moving
        //  c) Stopped
        let categorizedPoints = categorizePoints(points)


        // The second pass will group points into
        //  a) Discarded
        //  b) Runs (track, pause, virtual)
        //  c) Stops
        _runs = [StatsRun]()
        _stops = [StatsStop]()
        _discardedPoints = [StatsDiscardedPoint]()
        var tracks = [StatsTrack]()

        var group = [PointInfo]()
        for pt in categorizedPoints {
            if pt.category == PointCategory.poorQuality {
                _discardedPoints.append(StatsDiscardedPoint(gpx: pt.gpx))
                continue
            }

            if group.count == 0 {
                group.append(pt)
            } else {
                // If the category changed, flush the group and start a new group
                if pt.category == group[0].category {
                    group.append(pt)
                } else {
                    processGroup(group)
                    group.removeAll(keepingCapacity: true)
                    group.append(pt)
                }
            }
        }

        processGroup(group)
// print("end of track, stops: \(_stops)")
        tracks.append(StatsTrack(runs: _runs, stops: _stops, discardedPoints: _discardedPoints))
        return tracks
    }

    private func processGroup(_ group: [PointInfo]) {
        if group.count > 0 {
            switch group[0].category {
                case PointCategory.moving:
                    processRunGroup(group)
                case PointCategory.stopped:
                    processStoppedGroup(group)
                case PointCategory.poorQuality:
                    print("PoorQuality points should HAVE been filtered out already: \(group.count)")
            }
        }        
    }

    private func processRunGroup(_ group: [PointInfo]) {
        var statsRun = StatsRun(style: RunStyle.track)
        var prev = group[0]
        for index in 0..<group.count {
            let pt = group[index]
            if (prev.gpx.seconds(between: pt.gpx) > 10) {

                let virtualRun = StatsRun(style: RunStyle.virtual)
                virtualRun.add(gpx: prev.gpx)
                virtualRun.add(gpx: pt.gpx)
                _runs.append(virtualRun)

                _runs.append(statsRun)
                statsRun = StatsRun(style: RunStyle.track)
            }
            statsRun.add(gpx: pt.gpx)
            prev = pt
        }

        _runs.append(statsRun)
    }

    private func processStoppedGroup(_ group: [PointInfo]) {
        let duration = group[0].gpx.seconds(between: group[group.count - 1].gpx)
        if duration <= 15.0 {
            if let lastRun = _runs.last {
                let durationFromRecentRun = lastRun.points.last!.gpx.seconds(between: group[0].gpx)
                if durationFromRecentRun < 5.0 {
                    for p in group {
                        lastRun.add(gpx: p.gpx)
                    }
                    return
                }
            }
        }

        let stopStyle = duration < GpxAnalyzer.minimumStopDurationSeconds ? StatsStopStyle.paused : StatsStopStyle.stopped
        _stops.append(StatsStop(style: stopStyle, points: group.map { $0.gpx }) )
    }

    private func categorizePoints(_ points: [GpxPoint]) -> [PointInfo] {
        var category = [PointInfo]()
        if points.count < 1 {
            return category
        }

        var lastBadIndex: Int? = nil
        var idx = 0
        while idx < points.count {
            let p = points[idx]
            var ptCat = PointCategory.poorQuality
            var avgSpeed:Double? = nil
            if p.hasGoodDOP && p.hasGoodGPSFix {
                avgSpeed = recentAverageSpeed(points, idx, 15)
                if let avgSpeed = avgSpeed {
                    ptCat = avgSpeed >= GpxAnalyzer.minimumMovingAverageSpeedMetersSecond ? PointCategory.moving : PointCategory.stopped
                } else {
                    ptCat = PointCategory.moving
                }

                if idx > 0 {
                    let seconds = p.seconds(between: points[idx - 1])
                    let distance = p.distance(to: points[idx - 1])
                    let calculatedSpeed = p.speed(seconds: seconds, distance: distance)
                    let pointKmH = Converter.metersPerSecondToKilometersPerHour(metersSecond: p.speed)

                    if calculatedSpeed > 10.0 || pointKmH > 10.0 {
                        // 'max' overrides 0.0, which causes dividing issues
                        let lower = max(0.1, min(calculatedSpeed, pointKmH))
                        let higher = max(calculatedSpeed, pointKmH)
                        let ratio = higher / lower
                        if ratio > 20.0 {
// print("speed: \(pointKmH) [\(calculatedSpeed)] -- ratio: \(ratio), seconds: \(Int(seconds)), distance: \(distance): \(p.time)")
                            ptCat = PointCategory.poorQuality
                            if ratio > 20 && distance > 20 {
                                lastBadIndex = findLastBad(points, idx - 1, idx)
                            }
                        }
                    }
                }

            } else {
                ptCat = PointCategory.poorQuality
            }


            category.append(PointInfo(p, ptCat))
            idx += 1
            if let badIndex = lastBadIndex, badIndex > idx {
                for updateIndex in idx...badIndex {
                    category.append(PointInfo(points[updateIndex], PointCategory.poorQuality))
                }
                idx = badIndex + 1
            }
        }

        return category
    }

    func findLastBad(_ points: [GpxPoint], _ lastGoodIndex: Int, _ firstBadIndex: Int) -> Int {
        let lastGood = points[lastGoodIndex]
        let firstBad = points[firstBadIndex]
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

    private func getBounds(_ points: [GpxPoint]) -> (minLat:Double, minLon:Double, maxLat:Double, maxLon:Double) {
        var minLat = points[0].latitude
        var maxLat = points[0].latitude
        var minLon = points[0].longitude
        var maxLon = points[0].longitude
        for p in points {
            minLat = min(p.latitude, minLat)
            minLon = min(p.longitude, minLon)
            maxLat = max(p.latitude, maxLat)
            maxLon = max(p.longitude, maxLon)
        }

        return (minLat, minLon, maxLat, maxLon)
    }

    /// Calculates a weighted speed using the last few points of passed in array
    static private func smoothedSpeed_Weighted(_ points: [StatsPoint]) -> Double {
        let count = points.count
        if count == 0 {
            return 0
        }
        if count < 3 {
            return points[points.count - 1].gpx.speed
        }

        var weight = 0.0
        for idx in 0..<weighted.count {
            let pointIndex = count - (weighted.count - idx)
            weight += weighted[idx] * points[pointIndex].gpx.speed
        }
        return weight
    }

    static private func averageSpeed(_ points: [GpxPoint]) -> Double {
        let sumSpeed = points.reduce(0.0, { $0 + $1.speedKmH })
        return sumSpeed / Double(points.count)
    }

    // Calculates the average speed from the end of the array back the specified number of seconds.
    // If there aren't enough points, nil is returned
    static private func recentAverageSpeed(_ points: [StatsPoint]) -> Double {
        if points.count == 0 {
            return 0.0
        }

        var sumSpeed = 0.0
        for p in points {
            sumSpeed += p.gpx.speed
        }

        return sumSpeed / Double(points.count)
    }

    private func recentAverageSpeed(_ points: [GpxPoint], _ start: Int, _ seconds: Int) -> Double? {
        var sumSpeed = 0.0
        var index = start
        var secondsDiff = 0
        repeat {
            secondsDiff = Int(points[start].seconds(between: points[index]))
            sumSpeed += points[index].speed
            index -= 1
        } while (index >= 0 && secondsDiff < seconds)

        if secondsDiff >= seconds {
            return sumSpeed / Double(seconds)
        }
        return nil
    }
}
