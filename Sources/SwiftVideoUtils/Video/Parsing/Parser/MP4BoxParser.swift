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
        MP4TrackHeaderBox.self,
        
        MP4MediaBox.self,
        MP4MediaInformationBox.self,
        
        MP4ColorParameterBox.self,
        
        // Quicktime meta data
        MP4MetadataDatatypeDefinitionBox.self,
        MP4MetadataItemKeysBox.self,
        MP4MetadataItemListBox.self,
        MP4MetadataKeyDeclarationBox.self,
        MP4TimedMetadataMediaBox.self,
    ]
    
    static let defaultBoxTypesMap: [String: MP4ParsableBox.Type] = {
        boxTypes.reduce(into: .init()) { partialResult, boxType in
            partialResult[boxType.typeName] = boxType
        }
    }()
    
    
    private let reader: any MP4Reader
    private var nextBoxOffset: Int = 0
    
    var boxTypeMapOverrides: [String: MP4ParsableBox.Type]?
    
    func boxType(for typeName: String) -> MP4ParsableBox.Type? {
        boxTypeMapOverrides?[typeName] ?? Self.defaultBoxTypesMap[typeName]
    }
    
    public private(set) var endOfFile: Bool = false

    init(reader: any MP4Reader, boxTypeMapOverrides: [String: MP4ParsableBox.Type]? = nil) {
        self.reader = reader
        self.nextBoxOffset = reader.offset
        self.boxTypeMapOverrides = boxTypeMapOverrides
    }
    
    func readBox() async throws -> (any MP4Box)? {
        guard !self.endOfFile else { return nil }
        
        self.reader.offset = self.nextBoxOffset
        defer {
            self.reader.offset = self.nextBoxOffset
        }
        
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
        
        let remainingSizeOfBox = size - (reader.offset - startOffset)
        
        guard remainingSizeOfBox <= reader.remainingCount else {
            return nil
        }
        
        if self.boxType(for: typeName) != nil {
            // If the box is parsable, we can prepare the reader to read the full box
            try await self.reader.prepareToRead(count: min(remainingSizeOfBox + 16, reader.remainingCount))
        }
        
        let box = try await readBoxContent(typeName: typeName, size: size, 
                                           contentOffset: reader.offset - startOffset, lazy: true)
        
        self.nextBoxOffset = startOffset + size
        
        return box
    }
    
    private func readBoxContent(typeName: String, size: Int, contentOffset: Int, lazy: Bool) async throws -> any MP4Box {
        
        let contentReader: MP4SubrangeReader = .init(wrappedReader: reader, 
                                                     limit: min(size - contentOffset, reader.remainingCount))
        
        let result: any MP4Box
        if let boxType = self.boxType(for: typeName) {
            result = try await boxType.init(reader: contentReader)
            if contentReader.remainingCount != 0 {
                try await contentReader.printBytes()
            }
            assert(contentReader.remainingCount == 0)
        } else if let containerBox = try await MP4SimpleContainerBox(typeName: typeName, reader: contentReader) {
            result = containerBox
            assert(contentReader.remainingCount == 0)
        } else {
            contentReader.offset = 0
            result = try await MP4SimpleDataBox(typeName: typeName, reader: contentReader, lazy: true)
        }
        
        return result
    }
    
    func readBoxes() async throws -> [any MP4Box] {
        var result: [any MP4Box] = []
        
        while let box = try await readBox() {
            result.append(box)
        }
        
        return result
    }
}
