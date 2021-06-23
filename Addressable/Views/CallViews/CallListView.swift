//
//  CallListView.swift
//  Addressable
//
//  Created by Ari on 12/30/20.
//

import SwiftUI

struct CallListView: View, Equatable {
    static func == (lhs: CallListView, rhs: CallListView) -> Bool {
        lhs.selectedMenuItem == rhs.selectedMenuItem
    }

    @EnvironmentObject var app: Application
    @ObservedObject var viewModel: CallsViewModel
    @Binding var selectedMenuItem: MainMenu

    init(viewModel: CallsViewModel, selectedMenuItem: Binding<MainMenu>) {
        self.viewModel = viewModel
        self._selectedMenuItem = selectedMenuItem
    }

    var body: some View {
        VStack {
            if viewModel.incomingLeads.isEmpty && !viewModel.loading {
                HStack {
                    Spacer()
                    Text("No Calls from Leads")
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
                    .frame(
                        minWidth: 0,
                        maxWidth: .infinity,
                        minHeight: 0,
                        maxHeight: .infinity,
                        alignment: .center
                    )
            } else {
                List(viewModel.incomingLeads.filter { $0.status != "spam" && $0.status != "removed" }) { lead in
                    Button(action: {
                        app.verifyPermissions {
                            // In the case a user disallowed PN permissions on initial launch
                            // register for remote PN + Twilio here
                            DispatchQueue.main.async {
                                UIApplication.shared.registerForRemoteNotifications()
                            }
                            // Display Outgoing Call View
                            DispatchQueue.main.async {
                                app.currentView = .activeCall
                            }

                            guard let callManager = app.callManager else {
                                print("No CallManager to make phone call in CallListView")
                                return
                            }
                            // Get latest list of leads
                            callManager.getLatestIncomingLeadsList()
                            // Make outgoing call
                            callManager.startCall(to: lead)
                        }
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                if let name = lead.firstName {
                                    Text("\(name.contains("unknown")  ? "Unknown Name" : name)").font(.title2)
                                }
                                Text(lead.fromNumber ?? "Unknown Number").font(.subheadline)
                            }.padding(.vertical, 8)
                            Spacer()
                            if let score = lead.qualityScore {
                                switch score {
                                case 1:
                                    Text("Low Interest")
                                case 2:
                                    Text("Fair")
                                case 3:
                                    Text("Strong Lead")
                                default:
                                    // TODO: Consider returning a link to the Tag Form here
                                    Text("Untagged Lead")
                                }
                            }
                        }
                    }
                }.listStyle(PlainListStyle())
            }
        }
        .onAppear {
            viewModel.getLeads()
        }
    }
}

#if DEBUG
struct CallListView_Previews: PreviewProvider {
    static var previews: some View {
        let selectedMenuItem = Binding<MainMenu>(
            get: { MainMenu.campaigns }, set: { _ in }
        )
        CallListView(viewModel: CallsViewModel(provider: DependencyProvider()), selectedMenuItem: selectedMenuItem)
    }
}
#endif
