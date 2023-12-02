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
    static func from(cvImageBuffer imageBuffer: CVImageBuffer, affineTransform: CGAffineTransform?) -> CGImage? {
        let context = CIContext(options: nil)
        
        var ciImage = CIImage(cvImageBuffer: imageBuffer)
        
        if let affineTransform = affineTransform {
            ciImage = ciImage.transformed(by: affineTransform)
        }
        
        return context.createCGImage(ciImage, from: ciImage.extent)
    }
}
