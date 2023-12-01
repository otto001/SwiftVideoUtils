//
//  MP4Box.swift
//  WebDAV Photos
//
//  Created by Matteo Ludwig on 19.11.23.
//

import Foundation


public protocol MP4Box: CustomStringConvertible, MP4Writeable {
    var typeName: String { get }
    
    var children: [MP4Box] { get }
    
    func indentedString(level: Int) -> String
    
    func write(to writer: any MP4Writer) async throws
    func writeContent(to writer: any MP4Writer) async throws
}

// MARK: Child accessors
public extension MP4Box {
    var children: [MP4Box] { [] }
    
    func children(ofType typeName: any StringProtocol) -> [MP4Box] {
        children.filter { $0.typeName == typeName }
    }
    
    func children<T: MP4ParsableBox>(ofType type: T.Type) -> [T] {
        children.filter { $0.typeName == type.typeName }.map { $0 as! T }
    }
    
    func firstChild(ofType typeName: any StringProtocol) -> MP4Box? {
        children.first { $0.typeName == typeName }
    }
    
    func firstChild<T: MP4ParsableBox>(ofType type: T.Type) -> T? {
        children.first { $0.typeName == type.typeName } as? T
    }
    
    func requiredChild<T: MP4ParsableBox>(ofType type: T.Type) throws -> T {
        try firstChild(ofType: T.self).unwrapOrFail()
    }
}

// MARK: Path
public extension MP4Box {
    func children(path: [any StringProtocol]) -> [any MP4Box] {
        var workingArray: [any MP4Box] = [self]
        for step in path {
            guard !workingArray.isEmpty else { return [] }
            workingArray = workingArray.flatMap { box in
                box.children(ofType: step)
            }
        }
        
        return workingArray
    }
    
    func firstChild(path: [any StringProtocol]) -> (any MP4Box)? {
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
        children(path: path.split(separator: "."))
    }
    
    func firstChild(path: String) -> (any MP4Box)? {
        firstChild(path: path.split(separator: "."))
    }
    
    func requiredChild(path: String) throws -> (any MP4Box) {
        try firstChild(path: path.split(separator: ".")).unwrapOrFail(with: MP4Error.failedToFindBox(path: path))
    }
}

// MARK: CustomStringConvertible
public extension MP4Box {
    func indentedString(level: Int = 0) -> String {
        var result = String(repeating: "  ", count: level) + typeName
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
        
        try await writer.write(typeName, encoding: .ascii, length: 4)
        
        if size > UInt32.max {
            try await writer.write(UInt64(size), byteOrder: .bigEndian)
        }
    }
    
    func write(to writer: any MP4Writer) async throws {
        let contentWriter = MP4BufferWriter()
        try await writeContent(to: contentWriter)
        
        try await self.writeSizeAndTypename(to: writer, contentSize: contentWriter.data.count)
        
        try await writer.write(contentWriter.data)
    }
}
