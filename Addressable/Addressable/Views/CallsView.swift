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
        GeometryReader { geometry in
            VStack {
                Text("Addressable Leads").font(.title)
                CustomRefreshableScrollView(viewBuilder: {
                    VStack {
                        List(viewModel.dataSource) { lead in
                            Button(action: {
                                // call number
                                appDelegate.callManager?.startCall(to: lead.fromNumber ?? "")
                            }) {
                                Text(lead.firstName ?? "UNKNOWN")
                                Text(lead.fromNumber ?? "")
                            }
                        }
                    }
                }, size: geometry.size) {
                    viewModel.getLeads()
                }
            }
        }.onAppear {
            viewModel.getLeads()
        }
    }
}

struct CallsView_Previews: PreviewProvider {
    static var previews: some View {
        CallsView(viewModel: CallsViewModel(addressableDataFetcher: AddressableDataFetcher()))
    }
}
