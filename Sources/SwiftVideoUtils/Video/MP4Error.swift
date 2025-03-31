//
//  MP4Error.swift
//
//
//  Created by Matteo Ludwig on 22.11.23.
//

import Foundation


public enum MP4Error: Error {
    case failedToFindBox(path: String)
    case failedToParseBox(description: String)
    
    case noVideoTrack
    case failedToCreateCGImage
    
    case internalError(String)
    case featureNotSupported(String)

    case trackNotFound(UInt32)
    
    case stringEncodingError
    
    case fixedPointOverflow
    
    case unsupportedTrackFormat
    
    case endOfFile
    
    case insufficientDataReturned
    
    case tooFewBytes
    
    case inconsistentSampleTableBox
    
    case assetCannotBeEditedInplace
}
