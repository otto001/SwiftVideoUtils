// The Swift Programming Language
// https://docs.swift.org/swift-book


import Foundation
import CoreMedia
import CoreVideo

public class MP4FrameDecoder {
    public let asset: MP4Asset
    public let track: MP4Track
    
    public let videoTransform: CGAffineTransform?
    
    let decompressionSession: DecompressionSession
    public var videoFormat: CMFormatDescription {
        decompressionSession.formatDescription
    }
    
    public var suggestedThumbnailSample: MP4Index<UInt32> {
        get async throws {
            var result = MP4Index<UInt32>(index0: 0)
            
            if let secondSecond = try await self.track.syncSample(closestBefore: min(2, try await self.track.duration())) {
                result = max(result, secondSecond)
            }
            
            if let secondSyncSample = try? await self.track.syncSample(1) {
                result = max(result, secondSyncSample)
            }
            
            return result
        }
    }
    
    public init(asset: MP4Asset) async throws {
        self.asset = asset
        
        var videoTrack: MP4Track?
        for track in try await asset.tracks {
            if try await track.formatDescription.mediaType == .video {
                videoTrack = track
                break
            }
        }
        
        guard let videoTrack = videoTrack else {
            throw MP4Error.noVideoTrack
        }
        self.track = videoTrack
        

        self.videoTransform = try videoTrack.transformationMatrix.affineTransform

        
        self.decompressionSession = try .init(formatDescription: try await track.formatDescription)
    }
    
    public func cvImageBuffer(for sample: MP4Index<UInt32>) async throws -> CVImageBuffer {
        let sampleBuffer = try await track.sampleBuffers(for: sample..<sample+1, combineIntoSingleBuffer: true).first!
        
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
    
    public func cgImage(for sample: MP4Index<UInt32>) async throws -> CGImage {
        let imageBuffer = try await self.cvImageBuffer(for: sample)
        
        if let cgImage: CGImage = .from(cvImageBuffer: imageBuffer, affineTransform: self.videoTransform?.inverted()) {
            return cgImage
        } else {
            throw MP4Error.failedToCreateCGImage
        }
    }
}
