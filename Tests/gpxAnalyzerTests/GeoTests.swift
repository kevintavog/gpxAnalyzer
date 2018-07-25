import Foundation
import XCTest
@testable import GpxAnalyzerCore

import Foundation
import XCTest
@testable import GpxAnalyzerCore

class GeoTests : XCTestCase {
    func testBearing() {
        let expectedBearings:[(bearing: Int, lat1: Double, lon1: Double, lat2: Double, lon2: Double)] = [
            (348, 40.73423,  -73.989418,  40.734265, -73.989428),
            (168, 40.734265, -73.989428,  40.734229, -73.989418)
        ]

        for b in expectedBearings {
            let bearing = Geo.bearing(lat1: b.lat1, lon1: b.lon1, lat2: b.lat2, lon2: b.lon2)
            XCTAssertEqual(b.bearing, bearing)
        }
    }
}
