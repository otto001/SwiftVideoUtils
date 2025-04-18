//
//  MP4AppleMetaData.swift
//
//
//  Created by Matteo Ludwig on 23.11.23.
//

import Foundation
import CoreLocation


public struct MP4AppleMetaData {

    
    public var cameraLensModel: String?
    public var focalLength35mm: Int?
    
    public var make: String?
    public var model: String?
    public var software: String?
    public var creationDate: DateTime?
    public var location: CLLocation?
    
    public struct OrientationEntry: Equatable, Hashable {
        public let time: Range<UInt32>?
        public let orientation: Int16
    }
    public var orientations: [OrientationEntry] = []
    
    public init(moovBox: MP4MovieBox, reader: any MP4Reader) async throws {
        for metaBox in moovBox.children(path: "trak.meta") {
            if let itemListBox = metaBox.firstChild(ofType: MP4MetadataItemListBox.self),
               let keysListBox = metaBox.firstChild(ofType: MP4MetadataItemKeysBox.self) {
                
                let items = itemListBox.items(metadataItemKeysBox: keysListBox)
                
                if let item = items[.init(namespace: "mdta", value: "com.apple.quicktime.camera.lens_model")] {
                    self.cameraLensModel = item.asString()
                }
                
                if let item = items[.init(namespace: "mdta", value: "com.apple.quicktime.camera.focal_length.35mm_equivalent")] {
                    self.focalLength35mm = item.asInteger()
                }
            }
        }
        
        for trakBox in moovBox.tracks {
            guard let stblBox = trakBox.firstChild(path: "mdia.minf.stbl") as? MP4SampleTableBox,
                  let keyTableBox = stblBox.firstChild(path: "stsd.mebx.keys") as? MP4MetadataKeyTableBox else {
                continue
            }
            
            let keyDeclarations = keyTableBox.children.flatMap {
                $0.children(ofType: MP4MetadataKeyDeclarationBox.self)
            }
            
            guard keyDeclarations.count == 1 && keyDeclarations.first!.stringValue == "com.apple.quicktime.video-orientation" else {
                continue
            }
            
            do {
                for sample in try stblBox.samples {
                    let byteRange = try stblBox.byteRange(for: sample)
                    let time = stblBox.timeToSampleBox?.time(for: sample)
                    let orientation: Int16 = try await reader.readInteger(startingAt: byteRange.upperBound - 2, Int16.self, byteOrder: .bigEndian)
                    self.orientations.append(.init(time: time, orientation: orientation))
                }
            } catch {
                
            }
            
            break
        }
        
        if let metaBox = moovBox.firstChild(path: "meta"),
           let itemListBox = metaBox.firstChild(ofType: MP4MetadataItemListBox.self),
           let keysListBox = metaBox.firstChild(ofType: MP4MetadataItemKeysBox.self) {
            let items = itemListBox.items(metadataItemKeysBox: keysListBox)
            
            self.make = items[MP4MetadataItemKeysBox.Key(namespace: "mdta", value: "com.apple.quicktime.make")]?.asString()
            self.model = items[MP4MetadataItemKeysBox.Key(namespace: "mdta", value: "com.apple.quicktime.model")]?.asString()
            self.software = items[MP4MetadataItemKeysBox.Key(namespace: "mdta", value: "com.apple.quicktime.software")]?.asString()
            

            self.creationDate = items[MP4MetadataItemKeysBox.Key(namespace: "mdta", value: "com.apple.quicktime.creationdate")]?.asString().flatMap {
                DateTime(iso8601: $0)
            }

            let locationHorizontalAccuracy = items[MP4MetadataItemKeysBox.Key(namespace: "mdta", value: "com.apple.quicktime.location.accuracy.horizontal")]?.asDouble()
            
            
            self.location = items[MP4MetadataItemKeysBox.Key(namespace: "mdta", value: "com.apple.quicktime.location.ISO6709")]?.asString().flatMap {
                CLLocation(iso6709: $0, horizontalAccuracy: locationHorizontalAccuracy, verticalAccuracy: nil,
                           timestamp: self.creationDate?.utcTime)
            }
        }
    }
    
}
