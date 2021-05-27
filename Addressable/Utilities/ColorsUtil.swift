//
//  ColorsUtil.swift
//  Addressable
//
//  Created by Ari on 4/22/21.
//

import SwiftUI

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")

        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }

    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}

extension Color {
    public static var addressablePurple: Color {
        return Color(UIColor(red: 126/255, green: 0/255, blue: 181/255, alpha: 1.0))
    }
    public static var addressableLightGray: Color {
        return Color(UIColor(red: 250/255, green: 250/255, blue: 250/255, alpha: 1.0))
    }
    public static var addressableLighterGray: Color {
        return Color(UIColor(red: 221/255, green: 221/255, blue: 221/255, alpha: 1.0))
    }
    public static var addressableDarkGray: Color {
        return Color(UIColor(red: 112/255, green: 112/255, blue: 112/255, alpha: 1.0))
    }
    public static var addressableLightestGray: Color {
        return Color(UIColor(red: 203/255, green: 203/255, blue: 203/255, alpha: 1.0))
    }
    public static var addressableFadedBlack: Color {
        return Color(UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.5))
    }
    public static var addressableDarkerGray: Color {
        return Color(UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1.0))
    }
}
