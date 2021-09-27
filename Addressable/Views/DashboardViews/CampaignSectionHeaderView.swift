//
//  CampaignSectionHeaderView.swift
//  Addressable
//
//  Created by Ari on 6/3/21.
//

import SwiftUI

struct CampaignSectionHeaderView: View {
    var status: MailingStatus
    var count: Int

    @Binding var selectedFilters: [String]

    var body: some View {
        HStack {
            Text(status.rawValue)
                .font(Font.custom("Silka-Bold", size: 16))
                .foregroundColor(Color.black)
            Text(String(count))
                .font(Font.custom("Silka-Bold", size: 12))
                .foregroundColor(Color.white)
                .padding(4)
                .background(Color.addressableDarkGray)
                .clipShape(Circle())
            Spacer()
            if count > 3 {
                Button(action: {
                    // View All
                    selectedFilters = [status.rawValue]
                }) {
                    Text("View All")
                        .font(Font.custom("Silka-Bold", size: 12))
                        .foregroundColor(Color.black.opacity(0.3))
                        .underline()
                }
            }
        }.padding(.top, 10)
    }
}
#if DEBUG
struct CampaignSectionHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        let selectedFiltersPreview = Binding<[String]>(
            get: { [""] }, set: { _ in }
        )
        CampaignSectionHeaderView(
            status: MailingStatus.draft,
            count: 10,
            selectedFilters: selectedFiltersPreview
        )
    }
}
#endif
