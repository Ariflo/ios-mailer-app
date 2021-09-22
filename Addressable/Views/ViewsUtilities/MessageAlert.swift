//
//  MessageAlert.swift
//  Addressable
//
//  Created by Ari on 9/21/21.
//

import SwiftUI

struct MessageAlert: View {
    var body: some View {
        Group {
            Text("Changes may not be reflected on your preview automatically " +
                    "but will be updated on your mailing once changes have been saved.")
                .font(Font.custom("Silka-Bold", size: 14))
                .multilineTextAlignment(.center)
                .foregroundColor(Color.white)
        }
        .padding()
        .animation(.easeInOut(duration: 1.0))
        .transition(.opacity)
        .background(Color.black.opacity(0.5))
        .cornerRadius(10)
    }
}

struct MessageAlert_Previews: PreviewProvider {
    static var previews: some View {
        MessageAlert()
    }
}
