//
//  CDMarkdownItalic.swift
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

open class CDMarkdownItalic: CDMarkdownCommonElement {
    
    fileprivate static let regex = "()(\\*)([^\\*\\n]+?)(\\2)"
    
    open var font: CDFont? {
        didSet {
            self.font = font?.italic()
        }
    }

    open var color: CDColor?
    open var backgroundColor: CDColor?
    open var paragraphStyle: NSParagraphStyle?

    open var regex: String {
        return CDMarkdownItalic.regex
    }

    public init(font: CDFont? = nil,
                customItalicFont: CDFont? = nil,
                color: CDColor? = nil,
                backgroundColor: CDColor? = nil,
                paragraphStyle: NSParagraphStyle? = nil) {
        if let customItalicFont = customItalicFont {
            self.font = customItalicFont
        } else {
            self.font = font?.italic()
        }

        self.color = color
        self.backgroundColor = backgroundColor
        self.paragraphStyle = paragraphStyle
    }

    public func match(_ match: NSTextCheckingResult, attributedString: NSMutableAttributedString) {

        // Italic formatting can conflict with bullet lists if the list element is disabled or called afterwards.
        // Example: * Hello *World will be converted into (Italic)Hello (Normal)World
        //
        // This condition checks if the matched substring starts with '* '
        // and if it is either the beginning of the string or the beginning of a new line.
        //
        // If both conditions are true, the asterisk indicates a list element and the substitution will be skipped.
        let matchedText = attributedString.attributedSubstring(from: match.range).string
        if matchedText.starts(with: "* ") &&
            match.range.location == 0 || attributedString.string[match.range.location - 1] == "\n" {
            return
        }

        // deleting trailing markdown
        attributedString.deleteCharacters(in: match.nsRange(atIndex: 4))
        // formatting string (may alter the length)
        addAttributes(attributedString, range: match.nsRange(atIndex: 3))
        // deleting leading markdown
        attributedString.deleteCharacters(in: match.nsRange(atIndex: 2))
    }
}

private extension String {
    subscript(i: Int) -> Character {
        return self[index(startIndex, offsetBy: i)]
    }
}
