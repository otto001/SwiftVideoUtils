//
//  MP4TrackFragmentBox.swift
//  SwiftVideoUtils
//
//  Created by Matteo Ludwig on 30.03.25.
//

public class MP4TrackFragmentBox: MP4ConcreteBox {
    public static let typeName: MP4FourCC = "traf"
    public static let supportedChildBoxTypes: MP4BoxTypeMap = [
        MP4TrackFragmentHeaderBox.self,
        MP4TrackFragmentBaseMediaDecodeTimeBox.self,
        MP4TrackFragmentRunBox.self]
    
    public var readByteRange: Range<Int>?
    
    public var children: [any MP4Box]
    
    public var trackFragmentHeaderBox: MP4TrackFragmentHeaderBox? { firstChild(ofType: MP4TrackFragmentHeaderBox.self) }
    public var trackFragmentRunBoxes: [MP4TrackFragmentRunBox] { children(ofType: MP4TrackFragmentRunBox.self) }
    
    public init(children: [any MP4Box]) throws {
        self.children = children
    }
    
    public required convenience init(contentReader reader: MP4SequentialReader) async throws {
        try self.init(children: try await reader.readBoxes(parentType: Self.self))
    }
    
    public func writeContent(to writer: MP4Writer) async throws {
        try await writer.write(children)
    }
    
    public var overestimatedContentByteSize: Int {
        self.children.map {$0.overestimatedByteSize}.reduce(0, +)
    }
    
    public func totalSampleCount() -> Int {
        trackFragmentRunBoxes.map { Int($0.sampleCount) }.reduce(0, +)
    }
    
    public func totalSampleDuration() -> Int {
        let totalSampleCount = totalSampleCount()
        let defaultSampleDuration = Int(trackFragmentHeaderBox?.defaultSampleDuration ?? 0)
        
        var result: Int = totalSampleCount * defaultSampleDuration
        
        for runBox in trackFragmentRunBoxes {
            result += runBox.samples.compactMap(\.duration).map { Int($0) - defaultSampleDuration }.reduce(0, +)
        }
        
        return result
    }
}
