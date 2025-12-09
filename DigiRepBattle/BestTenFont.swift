//
//  BestTenFont.swift
//  DigiRepBattle
//

import SwiftUI
import CoreText
#if canImport(UIKit)
import UIKit
#endif

enum BestTenFont {
    static let name = "BestTen-CRT"
    private static var didRegister = false

    static func ensureRegistered() {
        guard !didRegister else { return }
        guard let url = Bundle.main.url(forResource: name, withExtension: "otf") else {
            return
        }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        didRegister = true
    }
}

extension Font {
    static func bestTen(size: CGFloat) -> Font {
        BestTenFont.ensureRegistered()
        return .custom(BestTenFont.name, size: size)
    }

#if canImport(UIKit)
    static func bestTen(style: UIFont.TextStyle) -> Font {
        BestTenFont.ensureRegistered()
        let size = UIFont.preferredFont(forTextStyle: style).pointSize
        return .custom(BestTenFont.name, size: size)
    }

    static var bestTenCaption: Font { bestTen(style: .caption1) }
    static var bestTenCaption2: Font { bestTen(style: .caption2) }
    static var bestTenFootnote: Font { bestTen(style: .footnote) }
    static var bestTenSubheadline: Font { bestTen(style: .subheadline) }
    static var bestTenHeadline: Font { bestTen(style: .headline) }
    static var bestTenTitle3: Font { bestTen(style: .title3) }
#endif
}
