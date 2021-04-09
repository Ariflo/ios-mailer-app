//
//  CallListView.swift
//  Addressable
//
//  Created by Ari on 12/30/20.
//

import SwiftUI

struct CallListView: View {
    @EnvironmentObject var app: Application
    @ObservedObject var viewModel: CallsViewModel

    init(viewModel: CallsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                CustomRefreshableScrollView(viewBuilder: {
                    if viewModel.incomingLeads.isEmpty && !viewModel.loading {
                        HStack {
                            Spacer()
                            Text("No Calls from Leads")
                            Spacer()
                        }
                    } else if viewModel.loading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                    List(viewModel.incomingLeads.filter { $0.status != "spam" && $0.status != "removed"}) { lead in
                        Button(action: {
                            app.verifyPermissions {
                                // In the case a user disallowed PN permissions on initial launch
                                // register for remote PN + Twilio here
                                DispatchQueue.main.async {
                                    UIApplication.shared.registerForRemoteNotifications()
                                }
                                // Display Outgoing Call View
                                DispatchQueue.main.async {
                                    app.displayCallView = true
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
                                    Text("\(lead.firstName == nil || lead.firstName!.contains("unknown")  ? "Unknown Name" : lead.firstName!)").font(.title2)
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
                }, size: geometry.size) {
                    viewModel.getLeads()
                }
            }
            .onAppear {
                viewModel.getLeads()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(
                        action: {
                            // Display Outgoing Call View
                            DispatchQueue.main.async {
                                app.displayCallView = true
                            }
                        }
                    ) {
                        Image(systemName: app.callManager?.currentActiveCall != nil ? "phone" : "")
                            .font(.system(size: 60))
                            .foregroundColor(Color(red: 78 / 255, green: 71 / 255, blue: 210 / 255))
                            .padding(.top, 8)
                    }
                }
            }
            .navigationBarTitle("Calls")
        }
    }
}

struct CallListView_Previews: PreviewProvider {
    static var previews: some View {
        CallListView(viewModel: CallsViewModel(addressableDataFetcher: AddressableDataFetcher()))
    }
}
