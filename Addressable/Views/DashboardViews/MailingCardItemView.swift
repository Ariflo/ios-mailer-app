//
//  MailingCardItemView.swift
//  Addressable
//
//  Created by Ari on 6/4/21.
//

import SwiftUI

enum MailingType: String {
    case radius = "RadiusMailing"
}

struct MailingCardItemView: View {
    var mailing: Mailing

    var body: some View {
        HStack(spacing: 12) {
            CalendarTileView(date: mailing.targetDropDate)
                .padding(.leading, 10)
            VStack(alignment: .leading, spacing: 8) {
                Text(mailing.name)
                    .foregroundColor(Color.black)
                    .font(Font.custom("Silka-Bold", size: 14))
                    .padding(.top, 8)
                mailing.type == MailingType.radius.rawValue ?
                    Text("Touch \(isTouchTwoMailing() ? "2" : "1")")
                    .font(Font.custom("Silka-Regular", size: 12))
                    .foregroundColor(Color.addressableFadedBlack)
                    .padding(.bottom, 8) : nil
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(Color.addressableFadedBlack)
                .imageScale(.small)
                .padding()
        }
        .frame(minWidth: 324, minHeight: 59)
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(Color.addressableFadedBlack, lineWidth: 1)
        )
        .background(Color.white)
        .padding(.top, 10)
    }
    private func isTouchTwoMailing() -> Bool {
        if let relatedTouchMailing = mailing.relatedMailing {
            return relatedTouchMailing.parentMailingID == nil
        } else {
            return false
        }
    }
}
