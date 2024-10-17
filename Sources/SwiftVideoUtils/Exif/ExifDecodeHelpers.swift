//
//  ExifDecodeHelpers.swift
//  SwiftVideoUtils
//
//  Created by Matteo Ludwig on 17.10.24.
//

import Foundation

extension ExifMetaData {
    
    static var exifDateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
        dateFormatter.timeZone = .init(abbreviation: "UTC")!
        dateFormatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        return dateFormatter
    }()
    
    static func decodeSubseconds(_ string: String) -> TimeInterval? {
        TimeInterval("0.\(string)")
    }
    
    static func decodeTimeOffset(_ string: String) -> TimeZone? {
        return TimeZone(offset: string)
    }
    
    static func extractDateTime(data: [String: Any], dateTimeKey: String, subsecKey: String?, timeOffsetKeys: [String]?) -> DateTime? {
        let deviceDateTime = (data[dateTimeKey] as? String).flatMap {
            Self.exifDateFormatter.date(from: $0)
        }
        guard var deviceDateTime else { return nil }
        
        if let subsecKey, let subsecTime = (data[subsecKey] as? String).flatMap(Self.decodeSubseconds(_:)) {
            deviceDateTime = deviceDateTime.addingTimeInterval(subsecTime)
        }
        
        if let timeOffsetKeys, let timeOffset = timeOffsetKeys.lazy.compactMap({(data[$0] as? String)}).first.flatMap(Self.decodeTimeOffset(_:)) {
            return DateTime(deviceTime: deviceDateTime, timeOffset: TimeInterval(timeOffset.secondsFromGMT()))
        } else {
            return DateTime(deviceTime: deviceDateTime, utcTime: nil)
        }
    }
}
