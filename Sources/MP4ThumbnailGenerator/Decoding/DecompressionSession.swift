//
//  DecompressionSession.swift
//
//
//  Created by Matteo Ludwig on 19.11.23.
//

import Foundation
import CoreMedia
import VideoToolbox


class DecompressionSession {
    let formatDescription: CMFormatDescription
    let decompressionSession: VTDecompressionSession
    
    init(formatDescription: CMFormatDescription) throws {
        self.formatDescription = formatDescription
        var decompressionSession: VTDecompressionSession? = nil
        let status = VTDecompressionSessionCreate(allocator: kCFAllocatorDefault,
                                                  formatDescription: formatDescription,
                                                  decoderSpecification: nil,
                                                  imageBufferAttributes: nil,
                                                  outputCallback: nil,
                                                  decompressionSessionOut: &decompressionSession)
        try checkOSStatus(status)
        
        self.decompressionSession = decompressionSession!
    }
    
    func decode(sampleBuffer: CMSampleBuffer, _ callback: @escaping (_ imageBuffer: CVImageBuffer?, _ error: Error?) -> Void) {
        var decodeInfoFlags: VTDecodeInfoFlags = []
        VTDecompressionSessionDecodeFrame(decompressionSession, sampleBuffer: sampleBuffer, flags: [], infoFlagsOut: &decodeInfoFlags) { status, infoFlags, imageBuffer, time1, time2 in
            
            callback(imageBuffer, errorFromOSStatus(status))
        }
    }
}
