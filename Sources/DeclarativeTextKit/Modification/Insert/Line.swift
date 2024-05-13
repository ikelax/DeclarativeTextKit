//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation

/// Ensures its ``content`` is enclosed by newline characters left and right upon insertion.
public struct Line: Insertable {
    public let content: Buffer.Content

    public init(_ content: Buffer.Content) {
        self.content = content
    }

    public func insert(in buffer: Buffer, at location: UTF16Offset) {
        let newlineBefore = location > buffer.range.lowerBound
            ? buffer.newline(at: location - 1)
            : true  // Favor not adding a newline at the start of a file
        let newlineAfter = location < buffer.range.upperBound
            ? buffer.newline(at: location)
            : false  // Favor ending with newline at EOF

        if !newlineAfter {
            buffer.insert(.newline, at: location)
        }

        content.insert(in: buffer, at: location)

        if !newlineBefore {
            buffer.insert(.newline, at: location)
        }
    }
}

// MARK: Half-Open Line

extension Line {
    /// Ensures its ``content`` is prepended by newline characters (left).
    ///
    /// At the ``Buffer``'s zero location or start position, does not prepend a newline.
    public struct StartsWithNewlineIfNeeded: Insertable {
        public let content: Buffer.Content

        @usableFromInline
        internal init(_ content: Buffer.Content) {
            self.content = content
        }

        @inlinable
        public func insert(in buffer: Buffer, at location: UTF16Offset) {
            let newlineBefore = location > buffer.range.lowerBound
                ? buffer.newline(at: location - 1)
                : true  // Favor not adding a newline at the start of a file

            content.insert(in: buffer, at: location)

            if !newlineBefore {
                buffer.insert(.newline, at: location)
            }
        }
    }

    /// Ensures its ``content`` is appended by a newline characters (right).
    ///
    /// At the ``Buffer``'s end position, appends a newline if ``insertFinalNewline`` is `true` so that documents end with a line break.
    public struct EndsWithNewlineIfNeeded: Insertable {
        public let content: Buffer.Content

        /// Whether to insert a newline at the end of a ``Buffer``.
        ///
        /// For whole text documents, this will ensure that the document's last character is a newline.
        public let insertFinalNewline: Bool = true

        @usableFromInline
        internal init(_ content: Buffer.Content) {
            self.content = content
        }

        @inlinable
        public func insert(in buffer: Buffer, at location: UTF16Offset) {
            let newlineAfter = location < buffer.range.upperBound
                ? buffer.newline(at: location)
                : !insertFinalNewline

            if !newlineAfter {
                buffer.insert(.newline, at: location)
            }

            content.insert(in: buffer, at: location)
        }
    }
}

extension String {
    @usableFromInline
    static var newline: String { "\n" }
}

extension Buffer {
    @usableFromInline
    func newline(at location: UTF16Offset) -> Bool {
        return character(at: location) == .newline
    }
}
