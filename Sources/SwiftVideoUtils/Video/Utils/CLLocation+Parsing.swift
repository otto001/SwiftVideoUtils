//
//  CLLocation+Parsing.swift
//
//
//  Created by Matteo Ludwig on 23.11.23.
//  Credit goes to https://gist.github.com/wata/9cd2d4779a55f5663fed0e07b05af1e6
//

import Foundation
import CoreLocation


extension CLLocation {
    convenience init?(iso6709: String, horizontalAccuracy: Double?, verticalAccuracy: Double?, timestamp: Date?) {
        let results = iso6709.capture(pattern: "([+-][0-9.]+)([+-][0-9.]+)([+-][0-9.]+)")
        guard let latitude = results[safe: 1] as NSString?,
              let longitude = results[safe: 2] as NSString? else {
            return nil
        }
        
        if let timestamp = timestamp {
            self.init(coordinate: .init(latitude: latitude.doubleValue, longitude: longitude.doubleValue),
                      altitude: (results[safe: 3] as? NSString)?.doubleValue ?? 0,
                      horizontalAccuracy: horizontalAccuracy ?? 0,
                      verticalAccuracy: verticalAccuracy ?? 0,
                      timestamp: timestamp)
        } else {
            self.init(latitude: latitude.doubleValue, longitude: longitude.doubleValue)
        }
    }
}
