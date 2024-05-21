//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation

public final class MutableStringBuffer: Buffer {
    @usableFromInline
    let storage: NSMutableString

    @inlinable
    public var range: Buffer.Range { Buffer.Range(location: 0, length: self.storage.length) }

    @inlinable
    public var content: Content { self.storage as Buffer.Content }

    public var selectedRange: Buffer.Range

    fileprivate init(
        storage: NSMutableString,
        selectedRange: Buffer.Range
    ) {
        self.storage = storage
        self.selectedRange = selectedRange
    }

    /// Create new `NSMutableString`-backed buffer based on `content`.
    ///
    /// > Invariant: The insertion point starts at the beginning of the buffer.
    public convenience init(_ content: Buffer.Content) {
        self.init(
            storage: NSMutableString(string: content),
            selectedRange: Buffer.Range(location: 0, length: 0)
        )
    }

    public func lineRange(for range: Buffer.Range) -> Buffer.Range {
        return self.storage.lineRange(for: range)
    }

    public func character(at location: Location) throws -> Buffer.Content {
        guard range.contains(location) else {
            throw BufferAccessFailure.outOfRange(location: location, available: range)
        }
        return self.storage.unsafeCharacter(at: location)
    }

    /// Raises an `NSExceptionName` of name `.rangeException` if `location` is out of bounds.
    public func unsafeCharacter(at location: Buffer.Location) -> Buffer.Content {
        return self.storage.unsafeCharacter(at: location)
    }

    public func insert(_ content: Content, at location: Location) throws {
        guard range.isValidInsertionPointLocation(at: location) else {
            throw BufferAccessFailure.outOfRange(location: location, available: range)
        }

        self.storage.insert(content, at: location)
    }

    public func delete(in deletedRange: Buffer.Range) throws {
        guard range.contains(deletedRange) else {
            throw BufferAccessFailure.outOfRange(requested: deletedRange, available: range)
        }

        self.storage.deleteCharacters(in: deletedRange)
        self.selectedRange.subtract(deletedRange)
    }

    public func replace(range replacementRange: Buffer.Range, with content: Buffer.Content) throws {
        guard range.contains(replacementRange) else {
            throw BufferAccessFailure.outOfRange(requested: replacementRange, available: range)
        }

        self.storage.replaceCharacters(in: replacementRange, with: content)
        self.selectedRange = self.selectedRange
            .subtracting(replacementRange)  // Removes potential overlap with the replacement range.
            .shifted(by: length(of: content))  // Nudges selection to the right if needed.
    }
}

extension MutableStringBuffer: ExpressibleByStringLiteral {
    public convenience init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }
}

extension MutableStringBuffer {
    /// Create a copy of `buffer`.
    public convenience init<Wrapping>(_ buffer: Wrapping) where Wrapping: Buffer {
        self.init(
            storage: NSMutableString(string: buffer.content),
            selectedRange: buffer.selectedRange
        )
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
