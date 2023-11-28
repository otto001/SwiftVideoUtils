//
//  MP4BoxParser.swift
//  WebDAV Photos
//
//  Created by Matteo Ludwig on 19.11.23.
//

import Foundation


class MP4BoxParser {
    static let boxTypes: [MP4ParsableBox.Type] = [
        MP4Avc1Box.self,
        MP4AvcCBox.self,
        MP4ChunkOffset32Box.self,
        MP4ChunkOffset64Box.self,
        MP4FileTypeBox.self,
        MP4HandlerReferenceBox.self,
        MP4Hvc1Box.self,
        MP4HvcCBox.self,
        MP4MediaHeaderBox.self,
        MP4MoovieBox.self,
        MP4MovieHeaderBox.self,
        MP4SampleDescriptionBox.self,
        MP4SampleSizeBox.self,
        MP4SampleTableBox.self,
        MP4SampleToChunkBox.self,
        MP4SyncSampleBox.self,
        MP4TimeToSampleBox.self,
        MP4TrackBox.self,
        
        MP4ColorParameterBox.self,
        
        // Quicktime meta data
        MP4MetadataItemKeysBox.self,
        MP4MetadataItemListBox.self,
        MP4TimedMetadataMediaBox.self,
    ]
    
    static let boxTypesMap: [String: MP4ParsableBox.Type] = {
        boxTypes.reduce(into: .init()) { partialResult, boxType in
            partialResult[boxType.typeName] = boxType
        }
    }()
    
    
    private let reader: any MP4Reader
    private var nextBoxOffset: Int = 0
    
    public private(set) var endOfFile: Bool = false

    init(reader: any MP4Reader) {
        self.reader = reader
        self.nextBoxOffset = reader.offset
    }
    
    func readBox() async throws -> (any MP4Box)? {
        guard !self.endOfFile else { return nil }
        
        self.reader.offset = self.nextBoxOffset
        
        guard reader.remainingCount >= 8 else {
            self.endOfFile = true
            return nil
        }
        
        try await self.reader.prepareToRead(count: min(16, reader.remainingCount))
        
        let startOffset = reader.offset
        
        var size = Int(try await reader.readInteger(UInt32.self, byteOrder: .bigEndian))
        
        guard let typeName = try await reader.readString(byteCount: 4, encoding: .ascii) else {
            return nil
        }
        guard typeName.allSatisfy({$0.isASCII && ($0.isLetter || $0.isNumber)}) else {
            return nil
        }
        
        if size == 0 {
            return nil
        } else if size == 1 {
            size = Int(try await reader.readInteger(UInt64.self, byteOrder: .bigEndian))
        }
        
        if Self.boxTypesMap[typeName]?.fullyParsable == true {
            let remainingSizeOfBox = size - (reader.offset - startOffset)
            try await self.reader.prepareToRead(count: min(remainingSizeOfBox + 16, reader.remainingCount))
        }
        
        let box = try await readBoxContent(typeName: typeName, size: size, contentOffset: reader.offset - startOffset, lazy: true)
        
        self.nextBoxOffset = startOffset + size
        
        return box
    }
    
    private func readBoxContent(typeName: String, size: Int, contentOffset: Int, lazy: Bool) async throws -> any MP4Box {
        
        let contentReader: MP4SubrangeReader = .init(wrappedReader: reader, limit: min(size - contentOffset, reader.remainingCount))
        
        if let boxType = Self.boxTypesMap[typeName] {
            return try await boxType.init(reader: contentReader)
        } else if let containerBox = try await MP4SimpleContainerBox(typeName: typeName, reader: contentReader) {
            return containerBox
        } else {
            contentReader.offset = 0
            return try await MP4SimpleDataBox(typeName: typeName, reader: contentReader, lazy: true)
        }
    }
    
    func readBoxes() async throws -> [any MP4Box] {
        var result: [any MP4Box] = []
        
        while let box = try await readBox() {
            result.append(box)
        }
        
        return result
    }
}
