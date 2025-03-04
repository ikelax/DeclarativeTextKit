//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

/// A text buffer contains UTF16 characters.
public protocol Buffer: AnyObject {
    typealias Location = UTF16Offset
    typealias Length = UTF16Length
    typealias Range = UTF16Range
    typealias Content = String

    var content: Content { get }

    /// Full range of ``content``.
    var range: Range { get }

    /// Selected range. Equals `{0,0}` in case of empty content.
    var selectedRange: Range { get set }

    /// Location where text would next be inserted at if the user types.
    ///
    /// In case of an active selection defaults to the start of the selection.
    var insertionLocation: Location { get set }

    /// Whether the buffer would insert text at an insertion point additively, or whether it is in selection mode and insertion would overwrite text.
    var isSelectingText: Bool { get }

    /// Change selected range in receiver.
    func select(_ range: Range)

    func lineRange(for range: Range) -> Range

    /// - Returns: A character-wide slice of ``content`` at `location`.
    /// - Throws: ``BufferAccessFailure`` if `location` exceeds ``range``.
    func character(at location: Location) throws -> Content

    /// - Returns: A slice of ``content`` in `range`.
    /// - Throws: ``BufferAccessFailure`` if `subrange` exceeds ``range``.
    func content(in subrange: Buffer.Range) throws -> Content

    /// Returns a character-wide slice of ``content`` at `location`.
    ///
    /// Useful for unchecked access to buffer contents e.g. in loops, requiring checks on the caller's side.
    ///
    /// > Warning: Raises an exception if `location` is out of bounds.
    func unsafeCharacter(at location: Location) -> Content

    /// Inserts `content` at `location` into the buffer, not affecting the typing location of ``selectedRange`` in the process.
    ///
    /// - Throws: ``BufferAccessFailure`` if `location` exceeds ``range``.
    func insert(_ content: Content, at location: Location) throws

    /// Inserts `content` like typing at the current typing location of ``selectedRange``.
    ///
    /// This replaces any existing selected text. The ``selectedRange`` is modified in the process:
    ///
    /// - inserting text at the insertion point moves the insertion point by `length(of: content)`,
    /// - replacing text moves the insertion point to the end of the inserted text (exiting the selection mode).
    func insert(_ content: Content) throws

    /// Deletes content from `deletedRange`.
    ///
    /// Deletion does not move the typing location of ``selectedRange`` to `deletedRange` in the process, but deleting from before ``insertionLocation-4ey6j`` will move the insertion further towards the beginning of the text.
    ///
    /// - Throws: ``BufferAccessFailure`` if `deletedRange` exceeds ``range``.
    func delete(in deletedRange: Range) throws

    /// - Throws: ``BufferAccessFailure`` if `replacementRange` exceeds ``range``.
    func replace(range replacementRange: Range, with content: Content) throws

    /// Wrapping changes inside `block` in a modification request to bundle updates.
    ///
    /// - Throws: ``BufferAccessFailure`` if changes to `affectedRange` are not permitted.
    func modifying<T>(affectedRange: Range, _ block: () -> T) throws -> T
}

import Foundation // For inlining isSelectingText as long as Buffer.Range is a typealias

extension Buffer {
    @inlinable @inline(__always)
    public var isSelectingText: Bool { selectedRange.length > 0 }

    @inlinable @inline(__always)
    public var insertionLocation: Location {
        get { selectedRange.location }
        set { selectedRange = Buffer.Range(location: newValue, length: 0) }
    }

    @inlinable @inline(__always)
    public func select(_ range: Range) {
        selectedRange = range
    }

    @inlinable @inline(__always)
    public func insert(_ content: Content) throws {
        try replace(range: selectedRange, with: content)
    }

    @inlinable @inline(__always)
    public func character(at location: Location) throws -> Content {
        return try content(in: .init(location: location, length: 1))
    }

    @inlinable @inline(__always)
    public func contains(range: Buffer.Range) -> Bool {
        // Appending at the trailing end of the buffer is technically outside of its range, but permitted.
        if range.length == 0 {
            return self.range.isValidInsertionPointLocation(at: range.location)
        }
        // Overwriting rules are the same as deletion rules.
        return self.range.contains(range)
    }
}
