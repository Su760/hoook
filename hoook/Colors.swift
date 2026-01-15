//
//  Colors.swift
//  hook
//
//  Official Hook Color Palette
//

import SwiftUI

extension Color {
    // Hex color initializer
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB (no alpha)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // MARK: - Official Hook Color Palette
    
    /// Primary Brand Blue: #06387b
    static let brandPrimary = Color(hex: "06387b")
    
    /// Medium Blue: #6598dd
    static let brandMediumBlue = Color(hex: "6598dd")
    
    /// Light Blue: #94b7e6
    static let brandLightBlue = Color(hex: "94b7e6")
    
    /// Light Gray: #e1e8ed
    static let brandLightGray = Color(hex: "e1e8ed")
    
    /// White: #ffffff
    static let brandWhite = Color.white
    
    /// Black: #000000
    static let brandBlack = Color.black
    
    // MARK: - Semantic Colors
    
    /// Navigation bar background
    static let navigationBackground = brandPrimary
    
    /// Navigation text and icons
    static let navigationText = brandWhite
    
    /// Screen background
    static let screenBackground = brandLightGray
    
    /// Card background
    static let cardBackground = brandWhite
    
    /// Card border or divider
    static let cardBorder = brandLightBlue
    
    /// Primary text (on light backgrounds)
    static let textPrimary = brandBlack
    
    /// Secondary text (on light backgrounds)
    static let textSecondary = brandBlack.opacity(0.65)
    
    /// Text on dark backgrounds (navigation, cards with brand background)
    static let textOnDark = brandWhite
    
    /// Primary button background
    static let buttonPrimaryBackground = brandPrimary
    
    /// Primary button text
    static let buttonPrimaryText = brandWhite
    
    /// Primary button pressed/highlighted state
    static let buttonPrimaryPressed = brandMediumBlue
    
    /// Secondary button background
    static let buttonSecondaryBackground = brandMediumBlue
    
    /// Secondary button text
    static let buttonSecondaryText = brandWhite
    
    /// Ghost/text button text
    static let buttonGhostText = brandPrimary
    
    /// Ghost button pressed background
    static let buttonGhostPressed = brandLightBlue.opacity(0.2)
    
    /// Active tab indicator
    static let tabActiveIndicator = brandMediumBlue
    
    /// Inactive navigation items
    static let navigationInactive = brandLightBlue
    
    /// Focus/selection indicators
    static let focusIndicator = brandMediumBlue
    
    // MARK: - Legacy Support (for backward compatibility)
    
    /// @available(*, deprecated, renamed: "brandPrimary")
    static let hookPrimary = brandPrimary
    
    /// @available(*, deprecated, renamed: "brandMediumBlue")
    static let hookAccent = brandMediumBlue
    
    /// @available(*, deprecated, renamed: "brandLightBlue")
    static let hookLightBlue = brandLightBlue
    
    /// @available(*, deprecated, renamed: "brandMediumBlue")
    static let hookMediumBlue = brandMediumBlue
    
    /// @available(*, deprecated, renamed: "brandBlack")
    static let hookBlack = brandBlack
    
    /// @available(*, deprecated, renamed: "brandPrimary")
    static let hookDarkBlue = brandPrimary
    
    /// @available(*, deprecated, renamed: "brandMediumBlue")
    static let hookOrange = brandMediumBlue
    
    /// @available(*, deprecated, renamed: "textOnDark")
    static let hookTextOnDark = textOnDark
    
    /// @available(*, deprecated, renamed: "brandPrimary")
    static let hookTextOnLight = brandPrimary
}
