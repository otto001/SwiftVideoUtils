//
//  File.swift
//  
//
//  Created by Matteo Ludwig on 25.12.23.
//

import Foundation


//class AudioSampleEntry(codingname) extends SampleEntry (codingname){
//   const unsigned int(32)[2] reserved = 0;
//   unsigned int(16) channelcount;
//   template unsigned int(16) samplesize = 16;
//   unsigned int(16) pre_defined = 0;
//   const unsigned int(16) reserved = 0 ;
//   template unsigned int(32) samplerate = { default samplerate of
//media}<<16;
//// optional boxes follow
//Box (); // further boxes as needed ChannelLayout();
//DownMixInstructions() []; DRCCoefficientsBasic() []; DRCInstructionsBasic() []; DRCCoefficientsUniDRC() []; DRCInstructionsUniDRC() [];
//// we permit only one DRC Extension box: UniDrcConfigExtension();
//// optional boxes follow SamplingRateBox();
//ChannelLayout();
//}


public class MP4Mp4aBox: MP4ConcreteBox {
    public static var typeName: MP4FourCC = "mp4a"
    public static var supportedChildBoxTypes: MP4BoxTypeMap = []
    
    public var reserved1: Data

    public var dataReferenceIndex: UInt16
    
    public var reserved2: UInt64
    public var channelCount: UInt16
    public var sampleSize: UInt16
    public var preDefined: UInt16
    public var reserved3: UInt16
    public var sampleRate: UInt32
    
    public var children: [MP4Box]
    
//    public init(reserved1: UInt64, channelCount: UInt16, sampleSize: UInt16, preDefined: UInt16, reserved2: UInt16, sampleRate: UInt32, children: [MP4Box]) {
//        self.reserved1 = reserved1
//        self.channelCount = channelCount
//        self.sampleSize = sampleSize
//        self.preDefined = preDefined
//        self.reserved2 = reserved2
//        self.sampleRate = sampleRate
//        self.children = children
//    }
    
    public required init(contentReader reader: MP4SequentialReader) async throws {
        self.reserved1 = try await reader.readData(count: 6)
        self.dataReferenceIndex = try await reader.readInteger(byteOrder: .bigEndian)
        self.reserved2 = try await reader.readInteger(byteOrder: .bigEndian)
        self.channelCount = try await reader.readInteger(byteOrder: .bigEndian)
        self.sampleSize = try await reader.readInteger(byteOrder: .bigEndian)
        self.preDefined = try await reader.readInteger(byteOrder: .bigEndian)
        self.reserved3 = try await reader.readInteger(byteOrder: .bigEndian)
        self.sampleRate = try await reader.readInteger(byteOrder: .bigEndian) >> 16
        
        try await reader.printBytes(mode: .both)
        self.children = []
        self.children = try await reader.readBoxes(parent: self)

    }
    
    public func writeContent(to writer: MP4Writer) async throws {
        try await writer.write(self.reserved1)
        try await writer.write(self.dataReferenceIndex, byteOrder: .bigEndian)
        try await writer.write(self.reserved2, byteOrder: .bigEndian)
        try await writer.write(self.channelCount, byteOrder: .bigEndian)
        try await writer.write(self.sampleSize, byteOrder: .bigEndian)
        try await writer.write(self.preDefined, byteOrder: .bigEndian)
        try await writer.write(self.reserved3, byteOrder: .bigEndian)
        try await writer.write(self.sampleRate << 16, byteOrder: .bigEndian)
        
        try await writer.write(self.children)
    }
}
