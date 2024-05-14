//
//  Read.swift
//
//
//  Created by Mikhail Labanov on 5/5/24.
//

import Foundation

func checkLength(actual: Int, expected: Int) throws -> Void {
  if (actual != expected) {
      throw ParseError.unexpectedValue(expected: expected, actual: actual)
  }
}

func deltaTime2MS(
  deltaTime: UInt32,
  division: Division,
  tempo: Tempo
) -> UInt32 {
    switch division {
    case .metric(let divisionMetric):
        return (
            (deltaTime * UInt32(tempo.microsecondsPerQuarterNote)) /
            UInt32(divisionMetric.ticksPerQuarterNote) /
            1000
        )
    case .timeCode(let divisionTimecode):
        return (deltaTime /
                UInt32(divisionTimecode.ticksPerFrame) /
                UInt32(divisionTimecode.fps)) * 1000
    }
}
