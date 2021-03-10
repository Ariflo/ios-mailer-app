//
//  MessageChatView.swift
//  Addressable
//
//  Created by Ari on 1/14/21.
//

import SwiftUI

struct MessageChatView: View {
    @ObservedObject var viewModel: MessagesViewModel
    @State var typingMessage: String = ""
    let lead: IncomingLead

    init(viewModel: MessagesViewModel, lead: IncomingLead) {
        self.viewModel = viewModel
        self.lead = lead
    }

    var body: some View {
        VStack {
            List {
                ForEach(viewModel.messages) { msg in
                    MessageView(currentMessage: msg).hideRowSeparator()
                }
            }
            HStack {
                TextField("Message...", text: $typingMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(minHeight: CGFloat(30))
                Button(action: {
                    viewModel.sendMessage(OutgoingMessage(
                                            incomingLeadID: lead.id,
                                            body: typingMessage,
                                            messageSid: viewModel.messageSid))
                    typingMessage = ""
                }) {
                    Text("Send")
                }
            }.frame(minHeight: CGFloat(50)).padding()
        }.onAppear {
            viewModel.getMessages(for: lead.id)
        }.navigationBarTitle(Text("\(lead.firstName != nil || lead.firstName!.contains("unknown")  ? "Unknown Name" : lead.firstName!)"), displayMode: .inline)
    }
}

extension View {
    func hideRowSeparator(
        insets: EdgeInsets = .defaultListRowInsets,
        background: Color = .white
    ) -> some View {
        modifier(HideRowSeparatorModifier(
            insets: insets,
            background: background
        ))
    }
}

extension EdgeInsets {
    static let defaultListRowInsets = Self(top: 10, leading: 16, bottom: 0, trailing: 16)
}

struct HideRowSeparatorModifier: ViewModifier {
    static let defaultListRowHeight: CGFloat = 44

    var insets: EdgeInsets
    var background: Color

    init(insets: EdgeInsets, background: Color) {
        self.insets = insets

        var alpha: CGFloat = 0
        UIColor(background).getWhite(nil, alpha: &alpha)
        assert(alpha == 1, "Setting background to a non-opaque color will result in separators remaining visible.")
        self.background = background
    }

    func body(content: Content) -> some View {
        content
            .padding(insets)
            .frame(
                minWidth: 0, maxWidth: .infinity,
                minHeight: Self.defaultListRowHeight,
                alignment: .leading
            )
            .listRowInsets(EdgeInsets())
            .background(background)
    }
}

struct MessageChatView_Previews: PreviewProvider {
    static var previews: some View {
        MessageChatView(viewModel:
                            MessagesViewModel(addressableDataFetcher:
                                                AddressableDataFetcher()),
                        lead: IncomingLead(
                            id: 1,
                            md5: nil,
                            fromNumber: nil,
                            toNumber: nil,
                            firstName: "Foo",
                            lastName: "Bar",
                            streetLine1: nil,
                            streetLine2: nil,
                            city: nil,
                            state: nil,
                            zipcode: nil,
                            crmID: nil,
                            status: "")
        )
    }
}
