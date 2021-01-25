//
//  CDMarkdownImage.swift
//  CDMarkdownKit
//
//  Created by Christopher de Haan on 12/15/16.
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

open class CDMarkdownImage: CDMarkdownLinkElement {

    fileprivate static let regex = "[!{1}]\\[([^\\[]*?)\\]\\(([^\\)]*)\\)"

    open var font: CDFont?
    open var color: CDColor?
    open var backgroundColor: CDColor?
    open var paragraphStyle: NSParagraphStyle?
    open var size: CGSize?

    open var regex: String {
        return CDMarkdownImage.regex
    }

    var delegate: CDMarkdownImageDelegate?

    open func regularExpression() throws -> NSRegularExpression {
        return try NSRegularExpression(pattern: regex,
                                       options: .dotMatchesLineSeparators)
    }

    public init(font: CDFont? = nil,
                color: CDColor? = CDColor.blue,
                backgroundColor: CDColor? = nil,
                paragraphStyle: NSParagraphStyle? = nil,
                size: CGSize? = nil) {
        self.font = font
        self.color = color
        self.backgroundColor = backgroundColor
        self.paragraphStyle = paragraphStyle
        self.size = size
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
        let nsString = attributedString.string as NSString
        let linkStartInResult = nsString.range(of: "(",
                                               options: .backwards,
                                               range: match.range).location
        let linkRange = NSRange(location: linkStartInResult,
                                length: match.range.length + match.range.location - linkStartInResult - 1)
        let linkURLString = nsString.substring(with: NSRange(location: linkRange.location + 1,
                                                             length: linkRange.length - 1))

        // deleting trailing markdown
        // needs to be called before formattingBlock to support modification of length
        attributedString.deleteCharacters(in: NSRange(location: match.range.location,
                                                      length: linkRange.length + 2))

        // load image
        #if os(iOS) || os(macOS) || os(tvOS)
        let textAttachment: NSTextAttachment
        if let url = URL(string: linkURLString),
            let customTextAttachment = self.delegate?.textAttachment(for: url) {
            textAttachment = customTextAttachment
            if let image = textAttachment.image {
                self.adjustTextAttachmentSize(textAttachment, forImage: image)
            }
        } else {
            textAttachment = NSTextAttachment()
        }
        #endif

        // replace text with image
        #if os(iOS) || os(macOS) || os(tvOS)
        let textAttachmentAttributedString = NSAttributedString(attachment: textAttachment)
        #elseif os(watchOS)
        let textAttachmentAttributedString = NSAttributedString()
        #endif
        attributedString.replaceCharacters(in: NSRange(location: match.range.location,
                                                       length: linkStartInResult - match.range.location - 1),
                                           with: textAttachmentAttributedString)

        #if os(iOS) || os(macOS) || os(tvOS)
        let formatRange = NSRange(location: match.range.location,
                                  length: 1)

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

    #if os(iOS) || os(macOS) || os(tvOS)
    // NSTextAttachment is not (yet) supported on watchOS
    private func adjustTextAttachmentSize(_ textAttachment: NSTextAttachment,
                                          forImage image: CDImage) {

        let scalingFactor: CGFloat

        if image.size.width >= image.size.height {
            var preferredWidth: CGFloat

            // Check if the image width exceeds the width of the view
            if let size = size,
               size.width <= image.size.width {
                // add padding to image
                preferredWidth = size.width - 10
            } else {
                preferredWidth = image.size.width
            }

            scalingFactor = image.size.width / preferredWidth
        } else {
            var preferredHeight: CGFloat

            // Check if the image height exceeds the height of the view
            if let size = size,
               size.height <= image.size.height {
                // add padding to image
                preferredHeight = size.height - 10
            } else {
                preferredHeight = image.size.height
            }

            scalingFactor = image.size.height / preferredHeight
        }

        textAttachment.bounds = CGRect(x: 0,
                                       y: 0,
                                       width: image.size.width / scalingFactor,
                                       height: image.size.height / scalingFactor)
    }
    #endif
}
