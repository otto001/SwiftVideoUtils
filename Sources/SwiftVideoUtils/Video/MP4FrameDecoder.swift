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
    public let track: MP4Track
    
    public let videoTransform: CGAffineTransform?
    
    let decompressionSession: DecompressionSession
    public var videoFormat: CMFormatDescription {
        decompressionSession.formatDescription
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
        let sampleBuffer = try await track.sampleBuffer(for: sample)
        
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
        
        if let cgImage: CGImage = .from(cvImageBuffer: imageBuffer, affineTransform: self.videoTransform) {
            return cgImage
        } else {
            throw MP4Error.failedToCreateCGImage
        }
    }
    
#if os(iOS)
    public func uiImage(for sample: MP4Index<UInt32>) async throws -> UIImage {
        var ciImage = CIImage(cvImageBuffer: try await cvImageBuffer(for: sample))
        if let videoTransform = self.videoTransform {
            ciImage = ciImage.transformed(by: videoTransform)
        }
        return UIImage(ciImage: ciImage)
    }
#endif
    
}
