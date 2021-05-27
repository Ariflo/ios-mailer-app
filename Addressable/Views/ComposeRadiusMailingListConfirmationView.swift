//
//  ComposeRadiusMailingConfirmationView.swift
//  Addressable
//
//  Created by Ari on 4/22/21.
//

import SwiftUI

struct ComposeRadiusMailingConfirmationView: View {
    var emptyMessage: String

    var body: some View {
        VStack(alignment: .center, spacing: 6) {
            Image("ZippyIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 250, height: 250)
            Text(emptyMessage)
                .font(Font.custom("Silka-Medium", size: 16))
                .padding(25)
                .multilineTextAlignment(.center)
        }.frame(
            minWidth: 0,
            maxWidth: .infinity,
            minHeight: 0,
            maxHeight: .infinity,
            alignment: .center
        )
    }
}

struct ComposeRadiusMailingConfirmationView_Previews: PreviewProvider {
    static var previews: some View {
        ComposeRadiusMailingConfirmationView(emptyMessage: "EMPTY_MESSAGE")
    }
}
