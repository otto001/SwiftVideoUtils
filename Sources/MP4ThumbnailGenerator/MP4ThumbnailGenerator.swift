// The Swift Programming Language
// https://docs.swift.org/swift-book


import Foundation
import CoreMedia


public class MP4ThumbnailGenerator {
    public let asset: MP4Asset
    
    let moovBox: MP4MoovieBox
    let stblBox: MP4SampleTableBox
    
    let decompressionSession: DecompressionSession
    var videoFormat: CMFormatDescription {
        decompressionSession.formatDescription
    }
    
    var numberOfKeyframes: Int {
        self.stblBox.syncSamplesBox?.syncSamples.count ?? Int(self.stblBox.sampleCount)
    }
    
    public init(asset: MP4Asset) async throws {
        self.asset = asset
        
        let moovBox = try await asset.moovBox
        
        guard let stblBox = moovBox.videoTrack?.sampleTableBox else {
            throw MP4Error.noVideoTrack
        }
        
        self.moovBox = moovBox
        self.stblBox = stblBox
        
        self.decompressionSession = try .init(formatDescription: try await asset.videoFormatDescription)
    }
    
    public func thumbnail(for keyframe: Int = 0) async throws -> CGImage {
        let sampleBuffer = try await asset.videoSampleBuffer(for: self.stblBox.syncSamplesBox?.syncSamples[keyframe] ?? .init(index0: UInt32(keyframe)))
        
        return try await withCheckedThrowingContinuation { continuation in
            self.decompressionSession.decode(sampleBuffer: sampleBuffer) { imageBuffer, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let imageBuffer = imageBuffer {
                    if let cgImage: CGImage = .from(cvImageBuffer: imageBuffer) {
                        continuation.resume(returning: cgImage)
                    } else {
                        continuation.resume(throwing: MP4Error.failedToCreateCGImage)
                    }
                } else {
                    fatalError("DecompressionSession.decode failed to return error or result.")
                }
            }
        }
    }
}
