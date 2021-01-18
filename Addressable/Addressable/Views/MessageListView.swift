//
//  MessagesView.swift
//  Addressable
//
//  Created by Ari on 12/30/20.
//

import SwiftUI

struct MessageListView: View {
    @ObservedObject var viewModel: MessagesViewModel
    @State var navigateToChat: Int?

    init(viewModel: MessagesViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Text("Addressable Messages").font(.title)
            VStack {
                List(viewModel.incomingLeadsWithMessages) { lead in
                    NavigationLink(destination: MessageChatView(
                        viewModel: viewModel,
                        lead: lead
                    )) {
                        Text(lead.first_name ?? "UNKNOWN")
                        Text(lead.from_number ?? "")
                    }
                }
            }
        }.onAppear {
            viewModel.getIncomingLeadsWithMessages()
        }
    }
}

struct MessageListView_Previews: PreviewProvider {
    static var previews: some View {
        MessageListView(viewModel: MessagesViewModel(addressableDataFetcher: AddressableDataFetcher()))
    }
}
