//
//  CallsView.swift
//  Addressable
//
//  Created by Ari on 12/30/20.
//

import SwiftUI

struct CallsView: View {
    @EnvironmentObject var appDelegate: AppDelegate
    @ObservedObject var viewModel: CallsViewModel
    var refreshControl = UIRefreshControl()

    init(viewModel: CallsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                CustomRefreshableScrollView(viewBuilder: {
                    List(viewModel.incomingLeads) { lead in
                        Button(action: {
                            appDelegate.verifyPermissions {
                                // In the case a user disallowed PN permissions on initial launch
                                // register for remote PN + Twilio here
                                DispatchQueue.main.async {
                                    UIApplication.shared.registerForRemoteNotifications()
                                }
                                // Make outgoing call
                                appDelegate.callManager?.startCall(to: lead)
                            }
                        }) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(lead.firstName ?? "UNKNOWN").font(.title2)
                                Text(lead.fromNumber ?? "").font(.subheadline)
                            }.padding(.vertical, 8)
                        }
                    }.listStyle(PlainListStyle())
                }, size: geometry.size) {
                    viewModel.getLeads()
                }
            }.onAppear {
                viewModel.getLeads()
            }
            .navigationBarTitle("Calls")
        }
    }
}

struct CallsView_Previews: PreviewProvider {
    static var previews: some View {
        CallsView(viewModel: CallsViewModel(addressableDataFetcher: AddressableDataFetcher()))
    }
}
