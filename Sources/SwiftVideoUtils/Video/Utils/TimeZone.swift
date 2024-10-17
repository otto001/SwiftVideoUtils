//
//  TimeZone.swift
//  SwiftVideoUtils
//
//  Created by Matteo Ludwig on 17.10.24.
//

import Foundation

extension TimeZone {
    init?(offset: String) {
        if offset == "Z" {
            self.init(secondsFromGMT: 0)
        } else if offset.count == 3 { // assume +/-HH
            if let hour = Int(offset) {
                self.init(secondsFromGMT: hour * 3600)
                return
            }
        } else if offset.count == 5 { // assume +/-HHMM
            if let hour = Int(offset.dropLast(2)), let min = Int(offset.dropFirst(3)) {
                self.init(secondsFromGMT: (hour * 60 + min) * 60)
                return
            }
        } else if offset.count == 6 { // assime +/-HH:MM
            let parts = offset.components(separatedBy: ":")
            if parts.count == 2 {
                if let hour = Int(parts[0]), let min = Int(parts[1]) {
                    self.init(secondsFromGMT: (hour * 60 + min) * 60)
                    return
                }
            }
        }

        return nil
    }
    
    init?(iso8601: String) {
        // remove yyyy-MM-ddTHH:mm:ss part first
        guard let timeZone = TimeZone(offset: String(iso8601.dropFirst(19))) else {
            return nil
        }
        self = timeZone
    }
}
