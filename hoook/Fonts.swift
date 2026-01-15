//
//  Fonts.swift
//  hook
//
//  Font extension for Montserrat
//

import SwiftUI

extension Font {
    // Montserrat font family
    // Note: Montserrat font files need to be added to the project
    // These will fall back to system fonts if Montserrat is not available
    
    static func montserrat(_ style: MontserratStyle = .regular, size: CGFloat = 17) -> Font {
        // Try to load Montserrat, fallback to system font
        if let font = UIFont(name: "Montserrat-\(style.rawValue)", size: size) {
            return Font(font)
        } else if let font = UIFont(name: "Montserrat\(style.rawValue.capitalized)", size: size) {
            return Font(font)
        } else {
            // Fallback to system font with similar weight
            return .system(size: size, weight: style.systemWeight)
        }
    }
    
    static func montserratBold(size: CGFloat = 17) -> Font {
        return montserrat(.bold, size: size)
    }
    
    static func montserratMedium(size: CGFloat = 17) -> Font {
        return montserrat(.medium, size: size)
    }
    
    static func montserratSemiBold(size: CGFloat = 17) -> Font {
        return montserrat(.semiBold, size: size)
    }
}

enum MontserratStyle: String {
    case regular = "Regular"
    case medium = "Medium"
    case semiBold = "SemiBold"
    case bold = "Bold"
    
    var systemWeight: Font.Weight {
        switch self {
        case .regular: return .regular
        case .medium: return .medium
        case .semiBold: return .semibold
        case .bold: return .bold
        }
    }
}
