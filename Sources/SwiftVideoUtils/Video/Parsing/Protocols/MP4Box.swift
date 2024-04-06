//
//  MP4Box.swift
//  WebDAV Photos
//
//  Created by Matteo Ludwig on 19.11.23.
//

import Foundation


public protocol MP4Box: CustomStringConvertible, MP4Writeable {
    var typeName: MP4FourCC { get }
    
    var children: [any MP4Box] { get }
    
    func indentedString(level: Int) -> String
    
    func write(to writer: any MP4Writer) async throws
    func writeContent(to writer: any MP4Writer) async throws
    
    var overestimatedContentByteSize: Int { get }
    
    var readByteRange: Range<Int>? { get set }
}

// MARK: Child accessors
public extension MP4Box {
    func children(ofType typeName: MP4FourCC) -> [any MP4Box] {
        children.filter { $0.typeName == typeName }
    }
    
    func children<T: MP4ConcreteBox>(ofType type: T.Type) -> [T] {
        children.compactMap { $0 as? T }
    }
    
    func firstChild(ofType typeName: MP4FourCC) -> (any MP4Box)? {
        children.first { $0.typeName == typeName }
    }
    
    func firstChild<T: MP4ParsableBox>(ofType type: T.Type) -> T? {
        children.first { $0 as? T != nil } as? T
    }
    
    func requiredChild<T: MP4ConcreteBox>(ofType type: T.Type) throws -> T {
        try firstChild(ofType: T.self).unwrapOrFail()
    }
}

// MARK: Path
public extension MP4Box {
    func children(path: [MP4FourCC]) -> [any MP4Box] {
        var workingArray: [any MP4Box] = [self]
        for step in path {
            guard !workingArray.isEmpty else { return [] }
            workingArray = workingArray.flatMap { box in
                box.children(ofType: step)
            }
        }
        
        return workingArray
    }
    
    func firstChild(path: [MP4FourCC]) -> (any MP4Box)? {
        // This may be faster with dfs but its fine for now
        var workingArray: [any MP4Box] = [self]
        for step in path {
            guard !workingArray.isEmpty else { return nil }
            workingArray = workingArray.flatMap { box in
                box.children(ofType: step)
            }
        }
        
        return workingArray.first
    }
    
    func children(path: String) -> [any MP4Box] {
        do {
            return try children(path: path.split(separator: ".").map {try .init($0)})
        } catch {
            return []
        }
    }
    
    func firstChild(path: String) -> (any MP4Box)? {
        do {
            return try firstChild(path: path.split(separator: ".").map {try .init($0)})
        } catch {
            return nil
        }
    }
    
    func requiredChild(path: String) throws -> (any MP4Box) {
        try firstChild(path: path).unwrapOrFail(with: MP4Error.failedToFindBox(path: path))
    }
}

// MARK: CustomStringConvertible
public extension MP4Box {
    func indentedString(level: Int = 0) -> String {
        var result = String(repeating: "  ", count: level) + typeName.description
        if !children.isEmpty {
            result += "\n" + children.map {$0.indentedString(level: level+1)}.joined(separator: "\n")
        }
        return result
    }
    
    var description: String {
        self.indentedString()
    }
}

public extension MP4Box {
    
    func writeSizeAndTypename(to writer: any MP4Writer, contentSize: Int) async throws {
        
        var size = contentSize + 8
        
        if size <= UInt32.max {
            try await writer.write(UInt32(size), byteOrder: .bigEndian)
        } else {
            try await writer.write(UInt32(1), byteOrder: .bigEndian)
            size += 8
        }
        
        try await writer.write(typeName)
        
        if size > UInt32.max {
            try await writer.write(UInt64(size), byteOrder: .bigEndian)
        }
    }
    
    func write(to writer: any MP4Writer) async throws {
        let contentWriter = MP4BufferWriter(context: writer.context)
        contentWriter.reserveCapacity(bytes: self.overestimatedContentByteSize)
        try await writeContent(to: contentWriter)
        
        try await self.writeSizeAndTypename(to: writer, contentSize: contentWriter.buffer.count)
        
        try await writer.write(contentWriter.buffer)
    }
    
    var overestimatedByteSize: Int {
        let contentSize = self.overestimatedContentByteSize
        if contentSize <= UInt32.max {
            return contentSize + 8
        } else {
            return contentSize + 16
        }
    }
}
