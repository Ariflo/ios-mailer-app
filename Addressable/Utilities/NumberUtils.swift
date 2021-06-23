//
//  NumberUtils.swift
//  Addressable
//
//  Created by Ari on 4/24/21.
//

import Foundation

extension Int {
    var roundedWithAbbreviations: String {
        let number = Double(self)
        let thousand = number / 1000
        let million = number / 1000000
        if million >= 1.0 {
            return "\(round(million * 10) / 10)M"
        } else if thousand >= 1.0 {
            return "\(round(thousand * 10) / 10)K"
        } else {
            return "\(self)"
        }
    }

    var roundedToNearestThousandWithAbbrev: String {
        return "\(self / 1000)K"
    }

    var roundedToNearestThousand: Int {
        return (self / 1000) * 1000
    }
}
