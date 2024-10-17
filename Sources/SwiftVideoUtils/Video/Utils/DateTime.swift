//
//  DateTime.swift
//  SwiftVideoUtils
//
//  Created by Matteo Ludwig on 17.10.24.
//
import Foundation


/// Represents a date and time in two different time zones: UTC and the device's local time zone. Since many devices are not timezone aware, not all media files carry the UTC time of their creation. In this case, the `utcTime` property will be `nil`. `deviceTime` will be set in most cases. However, be aware that `deviceTime` is not in UTC, eventhough it is a `Date` object. 
public struct DateTime: Codable {
    /// The time in the device's local time zone. This property is `nil` if the device time is not available.
    /// - Note: This property is not in UTC, even though it is a `Date`. While a `Date` is timezone agnostic, they are usually created in the device's local time zone or in UTC. In many cases, media will not carry timezone information, so the device time is not in UTC. If you plan to show the time to the local time the media was created, you need to set the date formatter's time zone to UTC in order to prevent it from converting the time to the device's local time zone.
    public var deviceTime: Date?

    /// The time in UTC. This property is `nil` if the UTC time is not available.
    public var utcTime: Date?
    
    /// Creates a new `DateTime`.
    /// - Parameters:
    ///  - deviceTime: The time in the device's local time zone.
    /// - utcTime: The time in UTC.
    public init(deviceTime: Date?, utcTime: Date?) {
        self.deviceTime = deviceTime
        self.utcTime = utcTime
    }
    
    /// Creates a new `DateTime`.
    /// - Parameters:
    /// - deviceTime: The time in the device's local time zone.
    /// - timeOffset: The time offset in seconds between the device's local time zone and UTC.
    /// - Note: The `utcTime` property will be set to `deviceTime` minus `timeOffset`.
    public init (deviceTime: Date, timeOffset: TimeInterval) {
        self.deviceTime = deviceTime
        self.utcTime = deviceTime.addingTimeInterval(-timeOffset)
    }
    
    /// Creates a new `DateTime`.
    /// - Parameters:
    /// - utcTime: The time in UTC.
    /// - timeOffset: The time offset in seconds between the device's local time zone and UTC.
    /// - Note: The `deviceTime` property will be set to `utcTime` plus `timeOffset`.
    public init (utcTime: Date, timeOffset: TimeInterval) {
        self.utcTime = utcTime
        self.deviceTime = utcTime.addingTimeInterval(timeOffset)
    }
    
    /// Creates a new `DateTime` from an ISO8601 string.
    /// - Parameters:
    /// - iso8601: The ISO8601 string.
    /// - Note: The ISO8601 string must contain the time zone information.
    public init?(iso8601: String) {
        guard let utcTime = dateFormatter.date(from: iso8601), let timeZone = TimeZone(iso8601: iso8601) else { return nil }
        self.utcTime = utcTime
        self.deviceTime = utcTime.addingTimeInterval(TimeInterval(timeZone.secondsFromGMT()))
    }
    
    /// The time offset in seconds between the device's local time zone and UTC. This property is `nil` if either `deviceTime` or `utcTime` is `nil`.
    public var timeOffset: TimeInterval? {
        if let deviceTime, let utcTime {
            return deviceTime.timeIntervalSince(utcTime)
        } else {
            return nil
        }
    }
    
    /// The time zone of `deviceTime`. This property is `nil` if either `deviceTime` or `utcTime` is `nil`.
    public var timeZone: TimeZone? {
        if let timeOffset {
            return TimeZone(secondsFromGMT: Int(timeOffset))
        } else {
            return nil
        }
    }
}

private var dateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.timeZone = .init(abbreviation: "UTC")!
    return formatter
}()
