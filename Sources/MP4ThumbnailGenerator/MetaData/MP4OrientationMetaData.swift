//
//  MP4OrientationMetaData.swift
//
//
//  Created by Matteo Ludwig on 23.11.23.
//

import Foundation


struct MP4OrientationMetaData {
    // TODO: Add timing information!
    var orientations: [Int16] = []
    
    init(moovBox: MP4MoovieBox, reader: any MP4Reader) async throws {
        for trakBox in moovBox.tracks {
            guard let stblBox = trakBox.firstChild(path: "mdia.minf.stbl") as? MP4SampleTableBox,
                  let keysBox = stblBox.firstChild(path: "stsd.mebx.keys") as? MP4MetadataItemKeysBox,
                  keysBox.keys.contains(MP4MetadataItemKeysBox.Key(namespace: "mdta", value: "com.apple.quicktime.video-orientation")) else {
                continue
            }
            
            for sample in 0..<stblBox.sampleCount {
                let byteRange = stblBox.byteRange(for: .init(index0: sample))
                reader.offset = byteRange.upperBound - 2
                orientations.append(try await reader.readInteger(byteOrder: .bigEndian))
            }
            
            break
        }
    }
}
