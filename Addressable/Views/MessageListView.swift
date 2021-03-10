//
//  MessagesView.swift
//  Addressable
//
//  Created by Ari on 12/30/20.
//

import SwiftUI

struct MessageListView: View {
    @ObservedObject var viewModel: MessagesViewModel
    @State var navigateToChat = false
    @State var selectedLead = IncomingLead(
        id: 0,
        md5: "",
        fromNumber: "",
        toNumber: "",
        firstName: "",
        lastName: "",
        streetLine1: "",
        streetLine2: "",
        city: "",
        state: "",
        zipcode: "",
        crmID: nil,
        status: ""
    )

    init(viewModel: MessagesViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                CustomRefreshableScrollView(viewBuilder: {
                    List(viewModel.incomingLeadsWithMessages) { lead in
                        Button(action: {
                            selectedLead = lead
                            navigateToChat = true
                        }) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("\(lead.firstName == nil || lead.firstName!.contains("unknown")  ? "Unknown Name" : lead.firstName!)").font(.title2)
                                Text(lead.fromNumber ?? "Unknown Number").font(.subheadline)
                            }.padding(.vertical, 8)
                        }
                    }
                    .listStyle(PlainListStyle())
                }, size: geometry.size) {
                    viewModel.getIncomingLeadsWithMessages()
                }
            }
            .background(
                NavigationLink(destination: MessageChatView(
                    viewModel: viewModel,
                    lead: selectedLead
                ),
                isActive: $navigateToChat) {}
            )
            .onAppear {
                viewModel.getIncomingLeadsWithMessages()
            }
            .navigationBarTitle("Messages")
        }
    }
}

struct MessageListView_Previews: PreviewProvider {
    static var previews: some View {
        MessageListView(viewModel: MessagesViewModel(addressableDataFetcher: AddressableDataFetcher()))
    }
}
