//
//  CDMarkdownImageDelegate.swift
//  CDMarkdownKit
//
//  Created by Felix Lisczyk on 30.03.19.
//  Copyright © 2019 Christopher de Haan. All rights reserved.
//

import Foundation

#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import Cocoa
#endif

public protocol CDMarkdownImageDelegate {
    #if os(iOS) || os(tvOS) || os(macOS)
    func textAttachment(for url: URL) -> NSTextAttachment
    #endif
}
