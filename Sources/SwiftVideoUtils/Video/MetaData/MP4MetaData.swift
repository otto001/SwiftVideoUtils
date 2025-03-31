//
//  MP4MetaData.swift
//
//
//  Created by Matteo Ludwig on 22.11.23.
//

import Foundation
import CoreLocation
import CoreMedia


public struct MP4MetaData {
    public var creationTime: Date
    public var modificationTime: Date
    
    public var duration: TimeInterval
    public var nextTrackID: Int
    
    public var tracksMetaData: [any MP4TrackMetaData]
    
    public var videoTracksMetaData: [MP4VideoTrackMetaData] {
        tracksMetaData.compactMap { $0 as? MP4VideoTrackMetaData }
    }
    
    public var appleMetaData: MP4AppleMetaData?
    
    public var location: CLLocation? {
        appleMetaData?.location
    }
    
    public init(asset: MP4Asset) async throws {
        let moovBox = try await asset.moovBox
        let movieHeaderBox = try moovBox.movieHeaderBox.unwrapOrFail()
            

        self.creationTime = movieHeaderBox.creationTime
        self.modificationTime = movieHeaderBox.modificationTime
        self.duration = try await asset.totalDuration()
        self.nextTrackID = Int(movieHeaderBox.nextTrackID)
        
        self.tracksMetaData = []
        
        for track in try await asset.tracks {
            if let trackMetaData = try await track.metaData() {
                self.tracksMetaData.append(trackMetaData)
            }
        }
        
        self.appleMetaData = try? await .init(moovBox: moovBox, reader: asset.reader)
    }
}
