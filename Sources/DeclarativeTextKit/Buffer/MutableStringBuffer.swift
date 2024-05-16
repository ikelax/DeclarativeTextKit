//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation

public final class MutableStringBuffer: Buffer {
    @usableFromInline
    let storage: NSMutableString

    @inlinable
    public var range: Buffer.Range { Buffer.Range(location: 0, length: self.storage.length) }

    @inlinable
    public var content: Content { self.storage as Buffer.Content }

    public private(set) var selectedRange: Buffer.Range

    fileprivate init(
        storage: NSMutableString,
        selectedRange: Buffer.Range
    ) {
        self.storage = storage
        self.selectedRange = selectedRange
    }

    public convenience init(_ content: Buffer.Content) {
        self.init(
            storage: NSMutableString(string: content),
            selectedRange: Buffer.Range(location: 0, length: 0)
        )
    }

    public func lineRange(for range: Buffer.Range) -> Buffer.Range {
        return self.storage.lineRange(for: range)
    }

    /// Raises an `NSExceptionName` of name `.rangeException` if `location` is out of bounds.
    public func unsafeCharacter(at location: Buffer.Location) -> Buffer.Content {
        return self.storage.unsafeCharacter(at: location)
    }

    public func select(_ range: Buffer.Range) {
        self.selectedRange = range
    }

    public func insert(_ content: Content, at location: Location) {
        self.storage.insert(content, at: location)
    }

    /// Raises an `NSExceptionName` of name `.rangeException` if any part of `range` lies beyond the end of the buffer.
    public func delete(in range: Buffer.Range) {
        self.storage.deleteCharacters(in: range)
    }

    public func replace(range: Buffer.Range, with content: Buffer.Content) {
        self.storage.replaceCharacters(in: range, with: content)
        self.select(Buffer.Range(location: range.location + length(of: content), length: 0))
    }
}

extension MutableStringBuffer: ExpressibleByStringLiteral {
    public convenience init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }
}

extension MutableStringBuffer: Equatable {
    public static func == (lhs: MutableStringBuffer, rhs: MutableStringBuffer) -> Bool {
        return lhs.selectedRange == rhs.selectedRange
            && lhs.storage.isEqual(rhs.storage)
    }
}

extension MutableStringBuffer: CustomStringConvertible {
    public var description: String {
        let result = NSMutableString(string: self.content)
        if self.isSelectingText {
            result.insert("}", at: self.selectedRange.endLocation)
            result.insert("{", at: self.selectedRange.location)
        } else {
            result.insert("{^}", at: self.selectedRange.location)
        }
        return result as String
    }
}
