//
//  ContentMessageView.swift
//  Addressable
//
//  Created by Ari on 1/14/21.
//

import SwiftUI

struct ContentMessageView: View {
    var contentMessage: String
    var isCurrentUser: Bool

    var body: some View {
        Text(contentMessage)
            .font(Font.custom("Silka-Regular", size: 16))
            .padding(10)
            .foregroundColor(isCurrentUser ? Color.white : Color.black)
            .background(isCurrentUser ?
                            Color.blue :
                            Color(UIColor(red: 240 / 255, green: 240 / 255, blue: 240 / 255, alpha: 1.0)))
            .cornerRadius(10)
    }
}

#if DEBUG
struct ContentMessageView_Previews: PreviewProvider {
    static var previews: some View {
        ContentMessageView(contentMessage: "Hi, I am your friend", isCurrentUser: false)
    }
}
#endif
