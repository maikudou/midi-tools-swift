//
//  Data.swift
//
//
//  Created by Mike Henkel on 5/3/24.
//

import Foundation

extension Data {
    func readUInt32BE(_ position: Data.Index) throws -> UInt32 {
        if (self.count < position + 4) {
            throw ParseError.outOfBounds
        }
        var result: UInt32 = UInt32(self[position]) << (3*8)
        result = result | UInt32(self[position+1]) << (2*8)
        result = result | UInt32(self[position+2]) << (1*8)
        result = result | UInt32(self[position+3])
        return result
    }
    
    mutating func appendUInt32BE(_ value: UInt32) -> Void {
        var localValue = value
        var data: [UInt8] = []
        data.append(UInt8(localValue & 0xFF))
        localValue >>= 8
        data.append(UInt8(localValue & 0xFF))
        localValue >>= 8
        data.append(UInt8(localValue & 0xFF))
        localValue >>= 8
        data.append(UInt8(localValue & 0xFF))
        return self.append(contentsOf: data.reversed())
    }
    
    
    mutating func appendUInt24BE(_ value: UInt32) -> Void {
        var localValue = value
        var data: [UInt8] = []
        data.append(UInt8(localValue & 0xFF))
        localValue >>= 8
        data.append(UInt8(localValue & 0xFF))
        localValue >>= 8
        data.append(UInt8(localValue & 0xFF))
        return self.append(contentsOf: data.reversed())
    }
    
    func readUInt16BE(_ position: Data.Index) throws -> UInt16 {
        if (self.count < position + 2) {
            throw ParseError.outOfBounds
        }
        var result: UInt16 = UInt16(self[position]) << (1*8)
        result = result | UInt16(self[position+1])
        return result
    }
    
    mutating func appendUInt16BE(_ value: UInt16) -> Void {
        var localValue = value
        var data: [UInt8] = []
        data.append(UInt8(localValue & 0xFF))
        localValue >>= 8
        data.append(UInt8(localValue & 0xFF))
        return self.append(contentsOf: data.reversed())
    }
    
    func readUInt8(_ position: Data.Index) throws -> UInt8 {
        if (self.count < position + 1) {
            throw ParseError.outOfBounds
        }
        return UInt8(self[position])
    }
    
    func readInt8(_ position: Data.Index) throws -> Int8 {
        if (self.count < position + 1) {
            throw ParseError.outOfBounds
        }
        return Int8(truncatingIfNeeded: self[position])
    }
    
    func read7bitWordLE(_ position: Data.Index) throws -> UInt16 {
        let lsb = try self.readUInt8(position)
        let msb = try self.readUInt8(position + 1)
        return UInt16((UInt16(msb) & 0x7f) << 7) + UInt16(lsb & 0x7f)
    }
    
    mutating func append7bitWordLE(_ value: UInt16) -> Void {
        let lsb = UInt8((value >> 7) & 0x7f)
        let msb = UInt8(value & 0x7f)
        
        return self.append(contentsOf: [msb, lsb])
    }
    
    func readVariableQuantity(
      _ position: Data.Index
    ) throws -> (bytesRead: UInt32, quantity: UInt32) {
        var currentPosition = position
        let result = try self.readUInt8(currentPosition)
        currentPosition += 1
        var value: UInt32 = UInt32(result)
        if ((value & 0x80) != 0) {
            // its not the last byte
        value = UInt32(result & 0x7f)
            var nextRead: UInt8
            repeat {
                nextRead = try self.readUInt8(currentPosition)
                currentPosition += 1
                value = (value << 7) + UInt32(nextRead & 0x7f)
            } while ((nextRead & 0x80) != 0)
        }
        return (UInt32(currentPosition - position), value)
    }
    
    func readVariableLengthData(
        _ position: Data.Index
    ) throws -> (bytesRead: UInt32, data: Data) {
          let (bytesRead, variableQuantity) = try self.readVariableQuantity(
            position
          )
          let length = variableQuantity
          let startPosition = UInt32(position) + bytesRead
          let endPosition = startPosition + length - 1
          
          if (endPosition >= self.count) {
              throw ParseError.outOfBounds
          }
          
          return (bytesRead + length,
            self.subdata(in: Range<Data.Index>(
                Data.Index(startPosition)...Data.Index(endPosition)
            ))
          )
      }
}
