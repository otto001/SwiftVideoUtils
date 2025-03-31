//
//  File.swift
//  
//
//  Created by Matteo Ludwig on 01.12.23.
//

import Foundation


public enum DataDebugFormatMode {
    case ascii
    case hex
    case both
    
    var characterWidth: Int {
        switch self {
        case .ascii:
            return 1
        case .hex:
            return 2
        case .both:
            return -1
        }
    }
    
    var characterSpacing: Int {
        switch self {
        case .ascii:
            return 0
        case .hex:
            return 1
        case .both:
            return -1
        }
    }
}

extension Data {
    
    private func debugString(mode: DataDebugFormatMode) -> String {
        switch mode {
        case .ascii:
            return String(self.map {
                return Character(UnicodeScalar($0))
            }).map {
                if $0.asciiValue == 0 {
                    return "0"
                } else if $0.isLetter || $0.isNumber {
                    return "\($0)"
                } else {
                    return "."
                }
            }.joined()
            
        case .hex:
            return withUnsafeBytes { rawBuffer in
                rawBuffer.withMemoryRebound(to: UInt8.self) { buffer in
                    buffer.map { value in
                        String(value, radix: 16).padding(toLength: 2, withPad: " ", startingAt: 0)
                    }.joined(separator: " ")
                }
            }
            
        case .both:
            fatalError()
        }
    }
    
    private func debugLines(mode: DataDebugFormatMode, grouping: Int = 4, groupsPerLine: Int = 2) -> [String] {
        guard mode != .both else {
            fatalError()
        }
        
        //let lineWidth = (grouping * (mode.characterWidth + mode.characterSpacing) - mode.characterSpacing) * groupsPerLine + (groupsPerLine-1) * 2
        
        var result: [String] = []
        
        let groupCount = (self.count+grouping-1)/grouping
        
        var remainingToPrint = count
        var currentLine: [String] = []
        
        for i in 0..<groupCount {
            guard remainingToPrint > 0 else { break }
            
            let readCount = Swift.min(grouping, remainingToPrint)
            let range = i*grouping..<Swift.min((i+1)*grouping, count)
            let data = self[range]
            
            let string = data.debugString(mode: mode)
            
            remainingToPrint -= readCount
            
            currentLine.append(string)
            
            if currentLine.count >= groupsPerLine {
                result.append(currentLine.joined(separator: "  "))
                currentLine.removeAll(keepingCapacity: true)
            }
        }
        
        if !currentLine.isEmpty {
            result.append(currentLine.joined(separator: "  "))
        }
        
        if result.count >= 2 {
            let lastLine = result[result.count-1]
            let beforeLastLine = result[result.count-2]
            result[result.count-1] = lastLine.padding(toLength: beforeLastLine.count,
                                                      withPad: " ", startingAt: 0)
        }
        
        return result
    }
    
    func debugString(mode: DataDebugFormatMode, grouping: Int = 4, groupsPerLine: Int = 2, singleLine: Bool = false) -> String {
        
        var lines: [String]
        
        switch mode {
        case .ascii:
            lines = debugLines(mode: .ascii, grouping: grouping, groupsPerLine: groupsPerLine)
        case .hex:
            lines = debugLines(mode: .hex, grouping: grouping, groupsPerLine: groupsPerLine)
        case .both:
            lines = zip(debugLines(mode: .ascii, grouping: grouping, groupsPerLine: groupsPerLine),
                        debugLines(mode: .hex, grouping: grouping, groupsPerLine: groupsPerLine)).map {
                "\($0)    |    \($1)"
            }
        }
        

        if singleLine {
            return lines.joined(separator: "    ")
        } else {
            return lines.enumerated().map { (i, line) in
                "\(i*grouping*groupsPerLine)".padding(toLength: 5, withPad: " ", startingAt: 0) + " \(line)"
            }.joined(separator: "\n")
        }
    }
}
