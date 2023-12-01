// The Swift Programming Language
// https://docs.swift.org/swift-book


import Foundation
import CoreMedia
import CoreVideo

#if os(iOS)
import UIKit
#endif

public class MP4FrameDecoder {
    public let asset: MP4Asset
    
    let moovBox: MP4MoovieBox
    let stblBox: MP4SampleTableBox
    
    let orientation: Int16?
    
    let decompressionSession: DecompressionSession
    var videoFormat: CMFormatDescription {
        decompressionSession.formatDescription
    }
    
    var numberOfKeyframes: Int {
        get throws {
            try self.stblBox.syncSamplesBox?.syncSamples.count ?? Int(try self.stblBox.sampleCount)
        }
    }
    
    public init(asset: MP4Asset) async throws {
        self.asset = asset
        
        let moovBox = try await asset.moovBox
        
        guard let stblBox = moovBox.videoTrack?.mediaBox?.mediaInformationBox?.sampleTableBox else {
            throw MP4Error.noVideoTrack
        }
        
        self.orientation = try await asset.metaData().orientation
        
        self.moovBox = moovBox
        self.stblBox = stblBox
        
        self.decompressionSession = try .init(formatDescription: try await asset.videoFormatDescription)
    }
    
    public func cvImageBuffer(for keyframe: Int = 0) async throws -> CVImageBuffer {
        let sampleBuffer = try await asset.videoSampleBuffer(for: self.stblBox.syncSamplesBox?.syncSamples[keyframe] ?? .init(index0: UInt32(keyframe)))
        
        return try await withCheckedThrowingContinuation { continuation in
            self.decompressionSession.decode(sampleBuffer: sampleBuffer) { imageBuffer, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let imageBuffer = imageBuffer {
                    continuation.resume(returning: imageBuffer)
                } else {
                    continuation.resume(throwing: MP4Error.internalError("DecompressionSession.decode failed to return error or result."))
                }
            }
        }
    }
    
    public func cgImage(for keyframe: Int = 0) async throws -> CGImage {
        let imageBuffer = try await self.cvImageBuffer(for: keyframe)
        
        if let cgImage: CGImage = .from(cvImageBuffer: imageBuffer) {
            return cgImage
        } else {
            throw MP4Error.failedToCreateCGImage
        }
    }
    
#if os(iOS)
    public func uiImage(for keyframe: Int = 0) async throws -> UIImage {
        return UIImage(ciImage: CIImage(cvImageBuffer: try await cvImageBuffer(for: keyframe)))
    }
#endif
    
}
