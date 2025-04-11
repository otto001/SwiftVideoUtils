//
//  MP4IOContext.swift
//  
//
//  Created by Matteo Ludwig on 23.12.23.
//

import Foundation



public struct MP4IOContext: Sendable {
    public enum FileType: Sendable {
        case isoMp4
        case quicktime
    }
    
    
    public var fileType: FileType?
    
    public init(fileType: FileType? = nil) {
        self.fileType = fileType
    }
}
