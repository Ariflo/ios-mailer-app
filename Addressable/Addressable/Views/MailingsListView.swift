//
//  MailingsView.swift
//  Addressable
//
//  Created by Arian Flores on 12/3/20.
//

import SwiftUI

struct MailingsListView: View {
    @State private var mailingItems: [MailingMailing] = []

    var body: some View {
        VStack {
            Text("Addressable Mailings").font(.title)
            Spacer()

            List(mailingItems) { mailing in
                Text(mailing.name)
            }
            Spacer()
        }.navigationBarHidden(true).onAppear {
            mailingItems = MailingsListViewModel().getMailings() ?? []
        }
    }
}

struct MailingsListView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MailingsListView()
        }
    }
}
