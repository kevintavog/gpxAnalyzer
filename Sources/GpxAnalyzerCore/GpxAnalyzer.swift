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

    // Below a certain speed, we're going to consider it highly likely the trace is at a stop point
    static let minimumMovingAverageSpeedMetersSecond = Converter.kilometersPerHourToMetersPerSecond(kmh: 0.05)
    static let minimumStopDurationSeconds = 8 * 60.0
    static let maximumTimeBetweenConsolidatedStops = 1 * 60 * 60.0

    var _runs = [StatsRun]()
    var _stops = [StatsStop]()
    var _discardedPoints = [StatsDiscardedPoint]()


    static public func generateStats(gpxTracks: [GpxTrack]) -> StatsGpx {
        let analyzer = GpxAnalyzer()
        var tracks = [StatsTrack]()
        var original = [GpxPoint]()
        var filtered = [GpxPoint]()
        for t in gpxTracks {
            for s in t.segments {
                let (stats, f) = analyzer.createTracks(s.points)
                tracks.append(contentsOf: stats)
                original += s.points
                filtered += f
            }
        }

        return StatsGpx(tracks: analyzer.finalizeTracks(tracks), original: original, filtered: filtered)
    }

    private func finalizeTracks(_ input: [StatsTrack]) -> [StatsTrack] {
        var tracks = [StatsTrack]()
        for t in input {
            let runs = consolidateRuns(t.runs)
            let stops = consolidateStops(t.stops, runs)
            if runs.count > 0 || stops.count > 0 {
                tracks.append(StatsTrack(runs: runs, stops: stops, discardedPoints: t.discardedPoints, vectors: t.vectors))
            }
else {
    print("Removed track \(t)")
}
        }

        return tracks
    }

    public func stopToRectangle(_ stop: StatsStop) -> GeoRectangle {
        return GeoRectangle(minLat: stop.minLat, minLon: stop.minLon, maxLat: stop.maxLat, maxLon: stop.maxLon)
    }

    private func consolidateStops(_ stops: [StatsStop], _ runs: [StatsRun]) -> [StatsStop] {
        if stops.count <= 1 {
            return stops
        }

        var statsCopy = stops
        var combined = false
        var response = [StatsStop]()
        var currentIdx = statsCopy.count - 1
        while currentIdx >= 0 {
            var current = statsCopy[currentIdx]
            var otherIdx = currentIdx - 1

// print("Comparing \(currentIdx) to [\(otherIdx) - 0] (\(current.startTime); \(current.durationSeconds))")
            while otherIdx >= 0 {
                let other = statsCopy[otherIdx]
                let includedInTime = current.startTime < other.startTime && current.endTime > other.endTime ||
                    other.startTime < current.startTime && other.endTime > current.endTime

                if includedInTime || Geo.within(meters: 5.0, first: stopToRectangle(current), second: stopToRectangle(other)) {
                    let secondsBetween = min(
                        abs(current.startTime.timeIntervalSince(other.endTime)), 
                        abs(other.startTime.timeIntervalSince(current.endTime)))

                    if secondsBetween < GpxAnalyzer.maximumTimeBetweenConsolidatedStops {
                        current = StatsStop(first: current, second: other)
                        combined = true
                        statsCopy.remove(at: otherIdx)
                    }
else {
    print("seconds between too long: \(secondsBetween)")
}
                }
                otherIdx -= 1
            }

// print(" --> adding \(current.startTime); \(current.durationSeconds)")
            response.append(current)
            if currentIdx == 0 {
                break
            }

            if statsCopy.count > 0 {
                statsCopy.remove(at: statsCopy.count - 1)
            }
            while currentIdx >= statsCopy.count {
                currentIdx -= 1
            }
        }

// print("combined: \(combined); result: \(response.count), initial: \(stops.count)")

        if combined {
            return consolidateStops(response, runs)
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

    private func createTracks(_ points: [GpxPoint]) -> ([StatsTrack], [GpxPoint]) {
        // Get rid of duplicate points
        // let filteredNearbyPoints = RemoveNearbyPoints.process(points)
        let filteredNearbyPoints = points

        // Categorize points
        //  a) Poor quality (DOP or Fix)
        //  b) Moving
        //  c) Stopped
        let categorizedPoints = CategorizePoints.process(filteredNearbyPoints)

        // Calculate vectors & remove noisy points
        let vectors = VectorAnalyzer.calculate(points: categorizedPoints)
        let cleanedCategorizedPoints = RemoveNoisyPoints.process(vectors)

        // Group remaining points
        //  a) Discarded
        //  b) Runs (track, pause, virtual)
        //  c) Stops
        _runs = [StatsRun]()
        _stops = [StatsStop]()
        _discardedPoints = [StatsDiscardedPoint]()
        var tracks = [StatsTrack]()

        var group = [StatsPoint]()
        for pt in cleanedCategorizedPoints {
            if pt.category == StatsPointCategory.poorQuality {
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
        tracks.append(StatsTrack(runs: _runs, stops: _stops, discardedPoints: _discardedPoints, vectors: vectors))
        return (tracks, filteredNearbyPoints)
    }

    private func processGroup(_ group: [StatsPoint]) {
        if group.count > 0 {
// print("processing \(group[0].category)")
            switch group[0].category! {
                case StatsPointCategory.moving:
                    processRunGroup(group)
                case StatsPointCategory.stopped:
                    processStoppedGroup(group)
                case StatsPointCategory.poorQuality:
                    print("PoorQuality points should HAVE been filtered out already: \(group.count)")
            }
        }        
    }

    private func processRunGroup(_ group: [StatsPoint]) {
        var statsRun = StatsRun(style: RunStyle.track)
        var prev = group[0]
        for index in 0..<group.count {
            let pt = group[index]
            if (prev.gpx.seconds(between: pt.gpx) > 10) {

                _runs.append(statsRun)

                let virtualRun = StatsRun(style: RunStyle.virtual)
                virtualRun.add(gpx: prev.gpx)
                virtualRun.add(gpx: pt.gpx)
                _runs.append(virtualRun)

                statsRun = StatsRun(style: RunStyle.track)
            }
            statsRun.add(gpx: pt.gpx)
            prev = pt
        }

        _runs.append(statsRun)
    }

    private func processStoppedGroup(_ group: [StatsPoint]) {
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
}
