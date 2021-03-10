//
//  SegmentedControlIconOptionView.swift
//  Addressable
//
//  Created by Ari on 3/4/21.
//

import SwiftUI

struct SegmentedControlIconOptionView: View, Hashable {
    let option: IncomingLeadTagOptions

    var body: some View {
        VStack {
            switch option {
            case .spam:
                OptionView(
                    systemIcon: "desktopcomputer",
                    typeOptionLabel: option.rawValue
                )
            case .person:
                OptionView(
                    systemIcon: "person",
                    typeOptionLabel: option.rawValue
                )
            case .lowInterest:
                OptionView(
                    systemIcon: "hand.thumbsdown",
                    typeOptionLabel: option.rawValue
                )
            case .fair:
                OptionView(
                    systemIcon: "smiley",
                    typeOptionLabel: option.rawValue
                )
            case .lead:
                OptionView(
                    systemIcon: "hand.thumbsup",
                    typeOptionLabel: option.rawValue
                )
            case .removeYes:
                OptionView(
                    systemIcon: "hand.thumbsup",
                    typeOptionLabel: option.rawValue
                )
            case .removeNo:
                OptionView(
                    systemIcon: "hand.thumbsdown",
                    typeOptionLabel: option.rawValue
                )
            }
        }
    }
}

struct OptionView: View {
    let systemIcon: String
    let typeOptionLabel: String

    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            Image(systemName: systemIcon)
            Text(typeOptionLabel).font(.caption)
        }
    }
}

struct SegmentedControlIconOptionView_Previews: PreviewProvider {
    static var previews: some View {
        SegmentedControlIconOptionView(option: .spam)
    }
}
