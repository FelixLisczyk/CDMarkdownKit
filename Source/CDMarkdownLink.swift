//
//  CDMarkdownLink.swift
//  CDMarkdownKit
//
//  Created by Christopher de Haan on 11/7/16.
//
//  Copyright © 2016-2018 Christopher de Haan <contact@christopherdehaan.me>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#if os(iOS) || os(tvOS) || os(watchOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif

open class CDMarkdownLink: CDMarkdownLinkElement {

    fileprivate static let regex = "\\[([^\\[]*?)\\]\\(([^\\)]*)\\)"

    open var font: CDFont?
    open var color: CDColor?
    open var backgroundColor: CDColor?
    open var paragraphStyle: NSParagraphStyle?

    open var regex: String {
        return CDMarkdownLink.regex
    }

    open func regularExpression() throws -> NSRegularExpression {
        return try NSRegularExpression(pattern: regex,
                                       options: .dotMatchesLineSeparators)
    }

    public init(font: CDFont? = nil,
                color: CDColor? = CDColor.blue,
                backgroundColor: CDColor? = nil,
                paragraphStyle: NSParagraphStyle? = nil) {
        self.font = font
        self.color = color
        self.backgroundColor = backgroundColor
        self.paragraphStyle = paragraphStyle
    }

    open func formatText(_ attributedString: NSMutableAttributedString,
                         range: NSRange,
                         link: String) {
        guard let encodedLink = link.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed)
            else {
                return
        }
        guard let url = URL(string: link) ?? URL(string: encodedLink) else { return }

        attributedString.addLink(url,
                                 toRange: range)
    }

    open func match(_ match: NSTextCheckingResult,
                    attributedString: NSMutableAttributedString) {
        guard match.numberOfRanges == 3 else { return }

        let markdownRange = match.range(at: 0)
        let linkTextRange = match.range(at: 1)
        let linkURLString = attributedString.attributedSubstring(from: match.range(at: 2)).string

        #if os(iOS) || os(macOS) || os(tvOS)
        // Deleting trailing markdown
        let trailingMarkdownRange = NSRange(location: linkTextRange.upperBound, length: markdownRange.upperBound - linkTextRange.upperBound)
        attributedString.deleteCharacters(in: trailingMarkdownRange)

        // Deleting leading markdown
        let leadingMarkdownRange = NSRange(location: markdownRange.location, length: linkTextRange.location - markdownRange.location)
        attributedString.deleteCharacters(in: leadingMarkdownRange)

        // Adjust the range for the deleted leading markdown character(s)
        let formatRange = NSRange(location: linkTextRange.location - leadingMarkdownRange.length, length: linkTextRange.length)

        formatText(attributedString,
                   range: formatRange,
                   link: linkURLString)
        addAttributes(attributedString,
                      range: formatRange,
                      link: linkURLString)
        #endif
    }

    open func addAttributes(_ attributedString: NSMutableAttributedString,
                            range: NSRange,
                            link: String) {
        attributedString.addAttributes(attributes,
                                       range: range)
    }
}
