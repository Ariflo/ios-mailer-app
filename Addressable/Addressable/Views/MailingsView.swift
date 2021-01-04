//
//  MailingsView.swift
//  Addressable
//
//  Created by Arian Flores on 12/3/20.
//

import SwiftUI

struct MailingsView: View {
    @ObservedObject var viewModel: MailingsViewModel
    var refreshControl = UIRefreshControl()

    init(viewModel: MailingsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Text("Addressable Mailings").font(.title)
                CustomRefreshableScrollView(viewBuilder: {
                    VStack {
                        List(viewModel.dataSource) { mailing in
                            Text(mailing.name)
                        }
                    }
                }, size: geometry.size) {
                    viewModel.getMailings()
                }
            }
        }.onAppear {
            viewModel.getMailings()
        }
    }
}

struct MailingsView_Previews: PreviewProvider {
    static var previews: some View {
        MailingsView(viewModel: MailingsViewModel(addressableDataFetcher: AddressableDataFetcher()))
    }
}
