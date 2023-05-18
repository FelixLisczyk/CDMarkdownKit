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
        #if os(iOS) || os(macOS) || os(tvOS)
        attributedString.deleteCharacters(in: NSRange(location: match.range.location,
                                                      length: linkRange.length + 2))
        #endif

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
        attributedString.replaceCharacters(in: NSRange(location: match.range.location,
                                                       length: linkStartInResult - match.range.location - 1),
                                           with: textAttachmentAttributedString)
        #endif

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

        guard var targetSize = self.size else {
            return
        }

        let imageSize = image.size

        // Don't scale images beyond their original size
        targetSize = CGSize(
            width: min(imageSize.width, targetSize.width),
            height: min(imageSize.height, targetSize.height)
        )

        let widthRatio  = targetSize.width  / imageSize.width
        let heightRatio = targetSize.height / imageSize.height

        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: imageSize.width * heightRatio, height: imageSize.height * heightRatio)
        } else {
            newSize = CGSize(width: imageSize.width * widthRatio,  height: imageSize.height * widthRatio)
        }

        textAttachment.bounds = .init(origin: .zero, size: newSize)

        // Resize the image to match the text attachment in order to save memory space.
        textAttachment.image = textAttachment.image?.withSize(newSize)
    }
    #endif
}

#if os(iOS) || os(macOS) || os(tvOS)
private extension CDImage {
    func withSize(_ newSize: CGSize) -> CDImage {
        guard Thread.isMainThread else { return self }
        #if os(iOS) || os(tvOS)
            let image = UIGraphicsImageRenderer(size: newSize).image { _ in
                draw(in: CGRect(origin: .zero, size: newSize))
            }
            return image.withRenderingMode(renderingMode)
        #elseif os(macOS)
            guard let bitmap = NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: Int(newSize.width),
                pixelsHigh: Int(newSize.height),
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .calibratedRGB,
                bytesPerRow: 0,
                bitsPerPixel: 0
            ) else { return self }

            bitmap.size = newSize

            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

            self.draw(in: NSRect(x: 0, y: 0, width: newSize.width, height: newSize.height), from: .zero, operation: .copy, fraction: 1.0)

            NSGraphicsContext.restoreGraphicsState()

            let newImage = NSImage(size: newSize)
            newImage.addRepresentation(bitmap)

            return newImage
        #endif
    }
}
#endif
