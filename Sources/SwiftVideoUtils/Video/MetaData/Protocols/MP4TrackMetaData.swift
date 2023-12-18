//
//  MP4TrackMetaData.swift
//
//
//  Created by Matteo Ludwig on 18.12.23.
//

import Foundation
import CoreMedia

public protocol MP4TrackMetaData {
    var mediaType: CMFormatDescription.MediaType { get }
    var mediaSubType: CMFormatDescription.MediaSubType?  { get }
    var trackWidth: Double { get }
    var trackHeight: Double { get }
}
