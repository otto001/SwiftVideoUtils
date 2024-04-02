//
//  MP4Writeable.swift
//  
//
//  Created by Matteo Ludwig on 01.12.23.
//

import Foundation


public protocol MP4Writeable {
    func write(to writer: any MP4Writer) async throws
    var overestimatedByteSize: Int { get }
}

