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
        MP4CompositionTimeToSampleBox.self,
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
    
    var knownContainerTypes: Set<String> = .init([
        "ctps",
        "dinf",
        "edts",
        "gmhd",
        "meta",
        "sdpd",
        "setu",
        "tapt",
        "tref",
        "udta"
    ])
    
    static let defaultBoxTypesMap: [String: MP4ParsableBox.Type] = {
        boxTypes.reduce(into: .init()) { partialResult, boxType in
            partialResult[boxType.typeName] = boxType
        }
    }()
    
    
    private let reader: any MP4Reader
    let strict: Bool
    private var nextBoxOffset: Int = 0
    
    var boxTypeMapOverrides: [String: MP4ParsableBox.Type]?
    
    func boxType(for typeName: String) -> MP4ParsableBox.Type? {
        boxTypeMapOverrides?[typeName] ?? Self.defaultBoxTypesMap[typeName]
    }
    
    public private(set) var endOfFile: Bool = false

    init(reader: any MP4Reader, strict: Bool = true, boxTypeMapOverrides: [String: MP4ParsableBox.Type]? = nil) {
        self.reader = reader
        self.strict = strict
        self.boxTypeMapOverrides = boxTypeMapOverrides
        
        self.nextBoxOffset = reader.offset
    }
    
    func readBox() async throws -> any MP4Box {
        guard !self.endOfFile else {
            throw MP4Error.endOfFile
        }
        
        self.reader.offset = self.nextBoxOffset
        defer {
            self.reader.offset = self.nextBoxOffset
        }
        
        guard reader.remainingCount >= 8 else {
            self.endOfFile = true
            throw MP4Error.endOfFile
        }
        
        try await self.reader.prepareToRead(count: min(16, reader.remainingCount))
        
        let startOffset = reader.offset
        
        var size = Int(try await reader.readInteger(UInt32.self, byteOrder: .bigEndian))
        
        if (size != 1 && size < 8) || size-8 > self.reader.remainingCount {
            throw MP4Error.failedToParseBox(description: "Box size `\(size)` invalid (below 8 or larger than parent box)")
        }
        
        guard let typeName = try await reader.readString(byteCount: 4, encoding: .ascii) else {
            throw MP4Error.failedToParseBox(description: "Failed to read FourCC")
        }
        guard typeName.allSatisfy({$0.isASCII && ($0.isLetter || $0.isNumber)}) else {
            throw MP4Error.failedToParseBox(description: "FourCC `\(typeName)` is not ascii")
        }
        
        if size == 1 {
            size = Int(try await reader.readInteger(UInt64.self, byteOrder: .bigEndian))
        }
        
        let remainingSizeOfBox = size - (reader.offset - startOffset)
        
        guard remainingSizeOfBox <= reader.remainingCount else {
            throw MP4Error.failedToParseBox(description: "Box size invalid (below 8 or larger than parent box)")
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
        
        var result: any MP4Box
        
        do {
            if let boxType = self.boxType(for: typeName) {
                result = try await boxType.init(reader: contentReader)
                if contentReader.remainingCount != 0 {
                    try await contentReader.printBytes()
                }
                
                if self.strict && contentReader.remainingCount > 0 {
                    // TODO: We could do something about that in the future
                    throw MP4Error.failedToParseBox(description: "Did not parse \(contentReader.remainingCount) bytes at the end of the box.")
                }
                
            } else if self.strict && self.knownContainerTypes.contains(typeName) {
                result = try await MP4SimpleContainerBox(typeName: typeName, reader: contentReader)
            } else if !self.strict, let containerBox = try? await MP4SimpleContainerBox(typeName: typeName, reader: contentReader) {
                result = containerBox
            } else {
                contentReader.offset = 0
                result = try await MP4SimpleDataBox(typeName: typeName, reader: contentReader, lazy: true)
            }
        } catch {
            switch error {
            case MP4Error.failedToParseBox, MP4Error.failedToParseBox:
                result = try await MP4ParsingErrorBox(typeName: typeName, reader: reader, error: error)
            default:
                throw error
            }
        }
        
        
        return result
    }
    
    func readBoxes() async throws -> [any MP4Box] {
        var result: [any MP4Box] = []
        
        do {
            while !self.endOfFile {
                result.append(try await readBox())
            }
        } catch MP4Error.endOfFile {
            
        }
        
        return result
    }
}
