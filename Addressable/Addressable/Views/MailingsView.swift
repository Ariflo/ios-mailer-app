//
//  MailingsView.swift
//  Addressable
//
//  Created by Arian Flores on 12/3/20.
//

import SwiftUI

struct MailingsView: View {
    @ObservedObject var viewModel: MailingsViewModel

    init(viewModel: MailingsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Text("Addressable Mailings").font(.title)
            Spacer()

            List(viewModel.dataSource) { mailing in
                Text(mailing.name)
            }

            Spacer()
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
