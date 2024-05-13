//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit

extension NSTextView {
    /// `NSString` contents of the receiver without briding overhead.
    @usableFromInline
    var nsMutableString: NSMutableString {
        guard let textStorage = self.textStorage else {
            preconditionFailure("NSTextView.textStorage expected to be non-nil")
        }
        return textStorage.mutableString
    }
}

extension NSTextView: Buffer {
    @inlinable
    public var range: Buffer.Range { self.nsMutableString.range }

    /// Raises an `NSExceptionName` of name `.rangeException` if `location` is out of bounds.
    @inlinable
    public func character(at location: UTF16Offset) -> Buffer.Content {
        return self.nsMutableString.character(at: location)
    }

    public func insert(_ content: Content, at location: Location) {
        self.nsMutableString.insert(content, at: location)
    }
}
