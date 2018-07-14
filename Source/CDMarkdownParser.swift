//
//  CDMarkdownParser.swift
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

open class CDMarkdownParser {

    // MARK: - Element Arrays
    fileprivate var escapingElements: [CDMarkdownElement]
    fileprivate var defaultElements: [CDMarkdownElement]
    fileprivate var unescapingElements: [CDMarkdownElement]

    open var customElements: [CDMarkdownElement]

    // MARK: - Basic Elements
    open let header: CDMarkdownHeader
    open let list: CDMarkdownList
    open let quote: CDMarkdownQuote
    open let link: CDMarkdownLink
    open let automaticLink: CDMarkdownAutomaticLink
    open let bold: CDMarkdownBold
    open let italic: CDMarkdownItalic
    open let code: CDMarkdownCode
    open let syntax: CDMarkdownSyntax
#if os(iOS) || os(macOS) || os(tvOS)
    open let image: CDMarkdownImage
#endif

    // MARK: - Escaping Elements
    fileprivate var codeEscaping = CDMarkdownCodeEscaping()
    fileprivate var escaping = CDMarkdownEscaping()
    fileprivate var unescaping = CDMarkdownUnescaping()

    // MARK: - Configuration
    // Enables or disables detection of URLs even without Markdown format
    open var automaticLinkDetectionEnabled: Bool = true
    open let font: CDFont

    open var fontColor: CDColor {
        didSet {
            self.header.color = fontColor
            self.list.color = fontColor
            self.quote.color = fontColor
            self.link.color = fontColor
            self.automaticLink.color = fontColor
            self.bold.color = fontColor
            self.italic.color = fontColor
            self.code.color = fontColor
            self.syntax.color = fontColor
            self.image.color = fontColor
        }
    }

    open var backgroundColor: CDColor {
        didSet {
            self.header.backgroundColor = backgroundColor
            self.list.backgroundColor = backgroundColor
            self.quote.backgroundColor = backgroundColor
            self.link.backgroundColor = backgroundColor
            self.automaticLink.backgroundColor = backgroundColor
            self.bold.backgroundColor = backgroundColor
            self.italic.backgroundColor = backgroundColor
            self.code.backgroundColor = backgroundColor
            self.syntax.backgroundColor = backgroundColor
            self.image.backgroundColor = backgroundColor
        }
    }

    open let paragraphStyle: NSParagraphStyle

    // MARK: - Initializer
    public init(font: CDFont = CDFont.systemFont(ofSize: 12),
                boldFont: CDFont? = nil,
                italicFont: CDFont? = nil,
                fontColor: CDColor = CDColor.black,
                backgroundColor: CDColor = CDColor.clear,
                paragraphStyle: NSParagraphStyle? = nil,
                imageSize: CGSize? = nil,
                automaticLinkDetectionEnabled: Bool = true,
                customElements: [CDMarkdownElement] = []) {
        self.font = font
        self.fontColor = fontColor
        self.backgroundColor = backgroundColor
        if let paragraphStyle = paragraphStyle {
            self.paragraphStyle = paragraphStyle
        } else {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.paragraphSpacing = 3
            paragraphStyle.paragraphSpacingBefore = 0
            paragraphStyle.lineSpacing = 1.38
            self.paragraphStyle = paragraphStyle
        }

        header = CDMarkdownHeader(font: font, color: fontColor, backgroundColor: backgroundColor, paragraphStyle: paragraphStyle)
        list = CDMarkdownList(font: font, color: fontColor, backgroundColor: backgroundColor, paragraphStyle: paragraphStyle)
        quote = CDMarkdownQuote(font: font, color: fontColor, backgroundColor: backgroundColor, paragraphStyle: paragraphStyle)
        link = CDMarkdownLink(font: font, color: fontColor, backgroundColor: backgroundColor, paragraphStyle: paragraphStyle)
        automaticLink = CDMarkdownAutomaticLink(font: font, color: fontColor, backgroundColor: backgroundColor, paragraphStyle: paragraphStyle)
        bold = CDMarkdownBold(font: font, customBoldFont: boldFont, color: fontColor, backgroundColor: backgroundColor, paragraphStyle: paragraphStyle)
        italic = CDMarkdownItalic(font: font, customItalicFont: italicFont, color: fontColor, backgroundColor: backgroundColor, paragraphStyle: paragraphStyle)
        code = CDMarkdownCode(font: font, color: fontColor, backgroundColor: backgroundColor, paragraphStyle: paragraphStyle)
        syntax = CDMarkdownSyntax(font: font, color: fontColor, backgroundColor: backgroundColor, paragraphStyle: paragraphStyle)
#if os(iOS) || os(macOS) || os(tvOS)
        image = CDMarkdownImage(font: font, color: fontColor, backgroundColor: backgroundColor, paragraphStyle: paragraphStyle, size: imageSize)
#endif

        self.automaticLinkDetectionEnabled = automaticLinkDetectionEnabled
        self.escapingElements = []
#if os(iOS) || os(macOS) || os(tvOS)
        self.defaultElements = [header, list, bold, italic]
#else
        self.defaultElements = [header, list, bold, italic]
#endif
        self.unescapingElements = []
        self.customElements = customElements
    }

    // MARK: - Element Extensibility
    open func addCustomElement(_ element: CDMarkdownElement) {
        customElements.append(element)
    }

    open func removeCustomElement(_ element: CDMarkdownElement) {
        guard let index = customElements.index(where: { someElement -> Bool in
            return element === someElement
        }) else {
            return
        }
        customElements.remove(at: index)
    }

    // MARK: - Parsing
    open func parse(_ markdown: String) -> NSAttributedString {
        return parse(NSAttributedString(string: markdown))
    }

    open func parse(_ markdown: NSAttributedString) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(attributedString: markdown)
        let mutableString = attributedString.mutableString
        mutableString.replaceOccurrences(of: "&nbsp;",
                                         with: " ",
                                         range: NSRange(location: 0,
                                                        length: mutableString.length))
        let range = NSRange(location: 0,
                            length: attributedString.length)
#if swift(>=4.0)
        attributedString.addAttribute(NSAttributedStringKey.font,
                                      value: font,
                                      range: range)
        attributedString.addAttribute(NSAttributedStringKey.foregroundColor,
                                      value: fontColor,
                                      range: range)
        attributedString.addAttribute(NSAttributedStringKey.backgroundColor,
                                      value: backgroundColor,
                                      range: range)
        attributedString.addAttribute(NSAttributedStringKey.paragraphStyle,
                                      value: paragraphStyle,
                                      range: range)
#else
        attributedString.addAttribute(NSFontAttributeName,
                                      value: font,
                                      range: range)
        attributedString.addAttribute(NSForegroundColorAttributeName,
                                      value: fontColor,
                                      range: range)
        attributedString.addAttribute(NSBackgroundColorAttributeName,
                                      value: backgroundColor,
                                      range: range)
        attributedString.addAttribute(NSParagraphStyleAttributeName,
                                      value: paragraphStyle,
                                      range: range)
#endif
        var elements: [CDMarkdownElement] = escapingElements
        elements.append(contentsOf: defaultElements)
        elements.append(contentsOf: customElements)
        elements.append(contentsOf: unescapingElements)
        elements.forEach { element in
            if automaticLinkDetectionEnabled || type(of: element) != CDMarkdownAutomaticLink.self {
                element.parse(attributedString)
            }
        }
        return attributedString
    }
}
