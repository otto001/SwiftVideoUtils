//
//  MP4IOContext.swift
//  
//
//  Created by Matteo Ludwig on 23.12.23.
//

import Foundation



public struct MP4IOContext {
    public enum FileType {
        case mp4
        case quicktime
    }
    
    
    public var fileType: FileType?
    
    public init(fileType: FileType? = nil) {
        self.fileType = fileType
    }
}
