//
//  MessagesView.swift
//  Addressable
//
//  Created by Ari on 12/30/20.
//

import SwiftUI

struct MessageListView: View, Equatable {
    static func == (lhs: MessageListView, rhs: MessageListView) -> Bool {
        lhs.selectedMenuItem == rhs.selectedMenuItem
    }

    @EnvironmentObject var app: Application
    @ObservedObject var viewModel: MessagesViewModel
    @State var navigateToChat = false
    @State var selectedLead = IncomingLead(
        id: 0,
        userID: 0,
        accountID: 0,
        createdAt: "",
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
        status: "",
        qualityScore: nil,
        calls: [],
        userNotes: [],
        voicemailUrl: nil
    )
    @Binding var selectedMenuItem: MainMenu

    init(viewModel: MessagesViewModel, selectedMenuItem: Binding<MainMenu>) {
        self.viewModel = viewModel
        self._selectedMenuItem = selectedMenuItem
    }

    var body: some View {
        VStack {
            if viewModel.incomingLeadsWithMessages.isEmpty && !viewModel.loading {
                HStack {
                    Spacer()
                    Text("No Messages from Leads")
                    Spacer()
                }.frame(
                    minWidth: 0,
                    maxWidth: .infinity,
                    minHeight: 0,
                    maxHeight: .infinity,
                    alignment: .center
                )
            } else if viewModel.loading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                RefreshableScrollView(refreshing: $viewModel.refreshMessagesData) {
                    ForEach(viewModel.incomingLeadsWithMessages) { lead in
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                if let name = lead.firstName {
                                    Text("\(name.contains("unknown")  ? "Unknown Name" : name)")
                                        .foregroundColor(Color.black)
                                        .font(Font.custom("Silka-Bold", size: 18))
                                        .padding(.top, 8)
                                }
                                Text(lead.fromNumber ?? "Unknown Number")
                                    .font(Font.custom("Silka-Regular", size: 16))
                                    .foregroundColor(Color.addressableFadedBlack)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color.addressableFadedBlack)
                                .imageScale(.medium)
                                .padding()
                        }
                        .onTapGesture {
                            viewModel.analyticsTracker.trackEvent(
                                .mobileLeadMessageThreadTapped,
                                context: app.persistentContainer.viewContext
                            )
                            selectedLead = lead
                            navigateToChat = true
                        }
                        .padding()
                        .background(Color.white)
                        .border(width: 1, edges: [.bottom], color: Color.gray.opacity(0.2))
                    }
                }
                .background(Color.addressableLightGray)
            }
        }
        .background(
            NavigationLink(destination: MessageChatView(
                viewModel: viewModel,
                lead: selectedLead
            ).environmentObject(app),
            isActive: $navigateToChat) {}
        )
        .onAppear {
            viewModel.getIncomingLeadsWithMessages { incomingLeads in
                if let pushEvent = app.pushNotificationEvent,
                   let leadId = pushEvent.incomingLeadMessage?.leadId,
                   let lead = incomingLeads.first(where: { $0.id == leadId }) {
                    selectedLead = lead
                    navigateToChat = true
                }
            }
        }
    }
}

#if DEBUG
struct MessageListView_Previews: PreviewProvider {
    static var previews: some View {
        let selectedMenuItem = Binding<MainMenu>(
            get: { MainMenu.campaigns }, set: { _ in }
        )
        MessageListView(
            viewModel: MessagesViewModel(provider: DependencyProvider()),
            selectedMenuItem: selectedMenuItem)
    }
}
#endif
