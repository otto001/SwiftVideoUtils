//
//  CGImage+CVImageBuffer.swift
//
//
//  Created by Matteo Ludwig on 20.11.23.
//

import CoreGraphics
import CoreVideo
import CoreImage


extension CGImage {
    static func from(cvImageBuffer imageBuffer: CVImageBuffer) -> CGImage? {
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        let context = CIContext(options: nil)
        
        return context.createCGImage(CIImage(cvImageBuffer: imageBuffer), from: CGRect(x: 0, y: 0, width: width, height: height))
    }
}
