//
//  UtilsReadTests.swift
//  
//
//  Created by Mikhail Labanov on 5/5/24.
//

import XCTest
@testable import MidiToolsSwift

final class UtilsReadTests: XCTestCase {
    func testCheckLengthGood() throws {
        XCTAssertNoThrow(try checkLength(actual: 0, expected: 0))
        XCTAssertNoThrow(try checkLength(actual: 10, expected: 10))
        XCTAssertNoThrow(try checkLength(actual: -20, expected: -20))
    }
    
    func testCheckLengthBad() throws {
        XCTAssertThrowsError(
            try checkLength(actual: 0, expected: 1)
        ) {error in
            XCTAssertEqual(error as! ParseError, ParseError.unexpectedValue(expected: 1, actual: 0))
        }
        XCTAssertThrowsError(
            try checkLength(actual: 1, expected: 0)
        ) {error in
            XCTAssertEqual(error as! ParseError, ParseError.unexpectedValue(expected: 0, actual: 1))
        }
        XCTAssertThrowsError(
            try checkLength(actual: -1, expected: 0)
        ) {error in
            XCTAssertEqual(error as! ParseError, ParseError.unexpectedValue(expected: 0, actual: -1))
        }
    }
    
    func testdeltaTime2MSMetricDivision() throws {
        XCTAssertEqual(deltaTime2MS(
            deltaTime: 6144,
            division: Division.metric(
                DivisionMetric(ticksPerQuarterNote: 96)),
            tempo: Tempo(
                microsecondsPerQuarterNote: 500000,
                beatsPerMinute: 120)
        ), 32000)
        
    }
    func testdeltaTime2MSTimecodeDivision() throws {
        XCTAssertEqual(deltaTime2MS(
            deltaTime: 1000,
            division: Division.timeCode(
                DivisionTimeCode(fps: 25, ticksPerFrame: 40)),
            tempo: Tempo(
                microsecondsPerQuarterNote: 500000,
                beatsPerMinute: 120)
        ), 1000)
    }
}
