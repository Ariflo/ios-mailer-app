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
        NavigationView {
            GeometryReader { geometry in
                CustomRefreshableScrollView(viewBuilder: {
                    List(viewModel.incomingLeadsWithMessages) { lead in
                        NavigationLink(destination: MessageChatView(
                            viewModel: viewModel,
                            lead: lead
                        )) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(lead.firstName ?? "UNKNOWN").font(.title2)
                                Text(lead.fromNumber ?? "").font(.subheadline)
                            }.padding(.vertical, 8)
                        }
                    }
                    .listStyle(PlainListStyle())
                }, size: geometry.size) {
                    viewModel.getIncomingLeadsWithMessages()
                }
            }
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
