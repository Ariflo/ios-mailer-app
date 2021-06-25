//
//  CallListSectionHeaderView.swift
//  Addressable
//
//  Created by Ari on 6/25/21.
//

import SwiftUI

struct CallListSectionHeaderView: View {
    var label: CallLabel
    var count: Int

    @Binding var displaySection: Bool

    var body: some View {
        HStack {
            Text(label.rawValue.capitalizingFirstLetter())
                .font(Font.custom("Silka-Bold", size: 16))
                .foregroundColor(Color.black)
            Text(String(count))
                .font(Font.custom("Silka-Bold", size: 12))
                .foregroundColor(Color.white)
                .padding(4)
                .background(Color.addressableDarkGray)
                .clipShape(Circle())
            Spacer()
            Button(action: {
                // Hide Section
                withAnimation(.easeIn) {
                    displaySection.toggle()
                }
            }) {
                Image(systemName: displaySection ? "chevron.up" : "chevron.down")
                    .foregroundColor(Color.addressableFadedBlack)
                    .imageScale(.small)
                    .padding()
            }
        }
        .padding()
        .background(Color.addressableLightGray)
    }
}
#if DEBUG
struct CallListSectionHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        let displaySectionBinding = Binding<Bool>(
            get: { true }, set: { _ in }
        )
        CallListSectionHeaderView(label: .inbox, count: 2, displaySection: displaySectionBinding)
    }
}
#endif
