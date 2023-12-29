//
//  MP4LeafBox.swift
//  WebDAV Photos
//
//  Created by Matteo Ludwig on 19.11.23.
//

import Foundation


public protocol MP4VersionedBox: MP4ConcreteBox {
    var version: MP4BoxVersion { get }
    var flags: MP4BoxFlags { get }
    
}

public extension MP4VersionedBox {
    var children: [MP4Box] { [] }
    static var supportedChildBoxTypes: MP4BoxTypeMap { [] }
}
//
//public class AudioSampleEntryQuicktimeV0: MP4VersionedBox {
//    
//}
//
//public class AudioSampleEntryQuicktimeV1: MP4VersionedBox {
//    
//}
//public class AudioSampleEntryQuicktimeV2: MP4VersionedBox {
//    
//}
//
//public protocol MP4BoxVersionProtocol: MP4Readable, MP4Writeable {
//   
//}


//
//public protocol MP4VersionedBoxWrapper: MP4VersionedBox {
//    var wrappedBox: any MP4VersionedBox { get }
//    var version: any MP4BoxVersionProtocol { get }
//}
//
//extension MP4VersionedBoxWrapper {
//    public var version: [MP4Box] { wrappedBox.children }
//    public var children: [MP4Box] { wrappedBox.children }
//}
