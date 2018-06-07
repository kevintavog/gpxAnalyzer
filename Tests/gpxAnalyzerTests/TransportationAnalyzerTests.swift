import Foundation
import XCTest
@testable import GpxAnalyzerCore

class TransportationAnalyzerTests : XCTestCase {
    func testSpeedCalculation() {
        let speedAndExpected = [0.0: [SpeedType(probability: 0.01, transportation: .foot)]]
        for (speed,expected) in speedAndExpected {
            let actual = TransportationAnalyzer.calculate(speedKmh: speed)
            compare(expected, actual)
        }
    }

    func compare(_ expected: [SpeedType], _ actual: [SpeedType]) {
        let str = "\(actual)"
        XCTAssertEqual(expected.count, actual.count, str)
        for idx in 0..<expected.count {
            XCTAssertEqual(expected[idx].probability, actual[idx].probability, str)
            XCTAssertEqual(expected[idx].transportation, actual[idx].transportation, str)
        }
    }
}
