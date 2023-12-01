//
//  Date+ReferenceDate.swift
//
//
//  Created by Matteo Ludwig on 30.11.23.
//

import Foundation


public extension Date {
    static let mp4ReferenceDate: Date = {
        //DateComponents(calendar: .init(identifier: .gregorian), year: 1904, month: 1, day: 1, hour: 0, minute: 0, second: 0).date!.timeIntervalSince1970).date!
        return Date(timeIntervalSince1970: -2082848400.0 + 3600)
    }()
}

