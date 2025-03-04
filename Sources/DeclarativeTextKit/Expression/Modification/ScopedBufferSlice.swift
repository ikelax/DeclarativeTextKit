//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

final class ScopedBufferSlice<Base>: Buffer
where Base: Buffer {
    static func appending(to base: Base) throws -> ScopedBufferSlice<Base> {
        return try self.init(
            base: base,
            scopedRange: .init(location: base.range.endLocation, length: 0)
        )
    }

    private let base: Base

    var content: Base.Content { base.content }
    var range: Base.Range { scopedRange }
    var selectedRange: Base.Range {
        get { base.selectedRange }
        set { base.selectedRange = newValue }
    }

    private(set) var scopedRange: Base.Range

    /// - Throws: ``BufferAccessFailure`` if `scopedRange` is outside of `base.range`
    init(
        base: Base,
        scopedRange: Base.Range
    ) throws {
        guard base.contains(range: scopedRange) else {
            throw BufferAccessFailure.outOfRange(
                requested: scopedRange,
                available: base.range
            )
        }
        self.base = base
        self.scopedRange = scopedRange
    }

    func lineRange(for range: Base.Range) -> Base.Range {
        return base.lineRange(for: range)
    }

    func content(in subrange: UTF16Range) throws -> Base.Content {
        guard contains(range: subrange) else {
            throw BufferAccessFailure.outOfRange(
                requested: subrange,
                available: scopedRange
            )
        }
        return try base.content(in: subrange)
    }

    func unsafeCharacter(at location: Location) -> Base.Content {
        return base.unsafeCharacter(at: location)
    }

    func delete(in deletedRange: Base.Range) throws {
        guard contains(range: deletedRange) else {
            throw BufferAccessFailure.outOfRange(
                requested: deletedRange,
                available: scopedRange
            )
        }
        guard deletedRange.length > 0 else { return }

        defer {
            self.scopedRange = self.scopedRange
                .resized(by: -deletedRange.length)
        }

        try base.delete(in: deletedRange)
    }

    func replace(range replacementRange: Base.Range, with content: Base.Content) throws {
        guard contains(range: replacementRange) else {
            throw BufferAccessFailure.outOfRange(
                requested: replacementRange,
                available: scopedRange
            )
        }

        defer {
            // Unlike regular Buffer replacements, we don't need to ever `.shift(by:)` the scoped range because all changes are confined to it.
            self.scopedRange = self.scopedRange
                .resized(by: -replacementRange.length)
                .resized(by: length(of: content))
        }

        try base.replace(range: replacementRange, with: content)
    }

    func insert(_ content: Base.Content, at location: Base.Location) throws {
        guard contains(range: .init(location: location, length: 0)) else {
            throw BufferAccessFailure.outOfRange(
                location: location,
                available: scopedRange
            )
        }

        defer {
            self.scopedRange = self.scopedRange
                .resized(by: length(of: content))
        }

        try base.insert(content, at: location)
    }

    func modifying<T>(affectedRange: Buffer.Range, _ block: () -> T) throws -> T {
        guard contains(range: affectedRange) else {
            throw BufferAccessFailure.outOfRange(
                requested: affectedRange,
                available: scopedRange
            )
        }

        return try base.modifying(affectedRange: affectedRange, block)
    }

    func modifyingScope<T>(_ block: () -> T) throws -> T {
        return try base.modifying(affectedRange: scopedRange, block)
    }
}
