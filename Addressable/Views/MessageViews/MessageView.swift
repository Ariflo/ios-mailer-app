//
//  MessageView.swift
//  Addressable
//
//  Created by Ari on 1/14/21.
//

import SwiftUI

struct MessageView: View {
    var currentMessage: Message

    var body: some View {
        HStack(alignment: .bottom, spacing: 15) {
            currentMessage.isIncoming ? nil : Spacer()
            ContentMessageView(contentMessage: currentMessage.body,
                               isCurrentUser: !currentMessage.isIncoming)
            currentMessage.isIncoming ? Spacer() : nil
        }
    }
}

#if DEBUG
struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        MessageView(
            currentMessage: Message(
                id: 1,
                incomingLeadID: 1,
                body: "Foo Message",
                isIncoming: false,
                messageSid: "fooBar",
                createdAt: "foo",
                updatedAt: "bar"))
    }
}
#endif
