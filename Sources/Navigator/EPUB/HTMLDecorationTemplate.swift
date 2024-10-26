//
//  Copyright 2024 Readium Foundation. All rights reserved.
//  Use of this source code is governed by the BSD-style license
//  available in the top-level LICENSE file of the project.
//

import UIKit
import SwiftSoup

/// An `HTMLDecorationTemplate` renders a `Decoration` into a set of HTML elements and associated stylesheet.
public struct HTMLDecorationTemplate {
    /// Determines the number of created HTML elements and their position relative to the matching DOM range.
    public enum Layout: String {
        /// A single HTML element covering the smallest region containing all CSS border boxes.
        case bounds
        /// One HTML element for each CSS border box (e.g. line of text).
        case boxes
    }

    /// Indicates how the width of each created HTML element expands in the viewport.
    public enum Width: String {
        /// Smallest width fitting the CSS border box.
        case wrap
        /// Fills the bounds layout.
        case bounds
        /// Fills the anchor page, useful for dual page.
        case viewport
        /// Fills the whole viewport.
        case page
    }

    let layout: Layout
    let width: Width
    let element: (Decoration) -> String
    let stylesheet: String?

    public init(layout: Layout, width: Width = .wrap, element: @escaping (Decoration) -> String = { _ in "<div/>" }, stylesheet: String? = nil) {
        self.layout = layout
        self.width = width
        self.element = element
        self.stylesheet = stylesheet
    }

    public init(layout: Layout, width: Width = .wrap, element: String = "<div/>", stylesheet: String? = nil) {
        self.init(layout: layout, width: width, element: { _ in element }, stylesheet: stylesheet)
    }

    public var json: [String: Any] {
        [
            "layout": layout.rawValue,
            "width": width.rawValue,
            "stylesheet": stylesheet as Any,
        ]
    }

    /// Creates the default list of decoration styles with associated HTML templates.
    public static func defaultTemplates(
        defaultTint: UIColor = .yellow,
        lineWeight: Int = 2,
        cornerRadius: Int = 3,
        alpha: Double = 0.3
    ) -> [Decoration.Style.Id: HTMLDecorationTemplate] {
        let padding = UIEdgeInsets(top: 0, left: 1, bottom: 0, right: 1)
        return [
            .highlight: .highlight(defaultTint: defaultTint, padding: padding, lineWeight: lineWeight, cornerRadius: cornerRadius, alpha: alpha),
            .note: .note(defaultTint: defaultTint)
        ]
    }

    /// Creates a new decoration template for the `highlight` style.
    public static func highlight(defaultTint: UIColor, padding: UIEdgeInsets, lineWeight: Int, cornerRadius: Int, alpha: Double) -> HTMLDecorationTemplate {
        highlightTemplate(defaultTint: defaultTint, padding: padding, lineWeight: lineWeight, cornerRadius: cornerRadius, alpha: alpha)
    }

    /// Creates a new decoration template for the `note` style.
    public static func note(defaultTint: UIColor) -> HTMLDecorationTemplate {
        noteTemplate(defaultTint: defaultTint)
    }
    
    private static func highlightTemplate(defaultTint: UIColor, padding: UIEdgeInsets, lineWeight: Int, cornerRadius: Int, alpha: Double) -> HTMLDecorationTemplate {
        let className = makeUniqueClassName(key: "highlight")
        return HTMLDecorationTemplate(
            layout: .boxes,
            element: { decoration in
                let config = decoration.style.config as! Decoration.Style.HighlightConfig
                let tint = config.tint ?? defaultTint
                let isActive = config.isActive
                var css = ""
                if isActive {
                    css += "background-color: \(tint.cssValue(alpha: alpha)) !important;"
                }
                return "<div class=\"\(className)\" style=\"\(css)\"/>"
            },
            stylesheet:
            """
            .\(className) {
                margin-left: \(-padding.left)px;
                padding-right: \(padding.left + padding.right)px;
                margin-top: \(-padding.top)px;
                padding-bottom: \(padding.top + padding.bottom)px;
                border-radius: \(cornerRadius)px;
                box-sizing: border-box;
            }
            """
        )
    }
    
    /// Stile nota con banda colorata laterale
    private static func noteTemplate(
        defaultTint: UIColor,
        topMargin: Int = -4,
        bottomMargin: Int = 0
    ) -> HTMLDecorationTemplate {
        let className = makeUniqueClassName(key: "sidemark")
        return HTMLDecorationTemplate(
            layout: .boxes,
            width: .page,
            element: { decoration in
                let config = decoration.style.config as? Decoration.Style.NoteConfig
                let tint = config?.tint ?? defaultTint
                let isActive = config?.isActive
                
                return
                """
                <div>
                    <div class="sidemark" style="background-color: \(tint.cssValue()) !important; margin-top: \(topMargin)px; margin-bottom: \(bottomMargin)px"></div>
                </div>
                """
            },
            stylesheet: """
            .sidemark {
                float: left;
                width: 6px;
                height: calc(100% + 12px);
                background-color: var(--tint);
                margin-left: 8px;
                border-radius: 3px;
                max-height: calc(100vh - 20px);
                overflow: hidden;
                bottom: 0;
            }
            [dir=rtl] .sidemark {
                float: right;
                margin-left: 0px;
                margin-right: 10px;
            }
            """
        )
    }
    
    private static var classNamesId = 0
    private static func makeUniqueClassName(key: String) -> String {
        classNamesId += 1
        return "readium-\(key)-\(classNamesId)"
    }
}
