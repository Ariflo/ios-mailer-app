//
//  MissedCallsView.swift
//  Addressable
//
//  Created by Ari on 10/21/21.
//

import SwiftUI

struct MissedCallsView: View {
    @Binding var subjectLead: IncomingLead?

    let playVoiceMailCallBack: () -> Void

    var body: some View {
        NavigationView {
            if let lead = subjectLead {
                List(lead.calls) { call in
                    HStack(spacing: 8) {
                        Text(call.date)
                            .font(Font.custom("Silka-Regular", size: 14))
                        Spacer()
                        Text(call.duration)
                            .font(Font.custom("Silka-Regular", size: 14))
                        Spacer()
                        call.voicemailURL != nil ?
                            Text("Play Voicemail")
                            .font(Font.custom("Silka-Medium", size: 14))
                            .padding(8)
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color.white)
                            .background(Color.addressablePurple)
                            .cornerRadius(5)
                            .onTapGesture {
                                guard let voicemailUrl = call.voicemailURL,
                                      let url = URL(string: voicemailUrl) else { return }
                                playVoiceMailCallBack()
                                UIApplication.shared.open(url)
                            } : nil
                    }
                }
                .listStyle(PlainListStyle())
                // swiftlint:disable line_length
                .navigationBarTitle(Text("Call History " +
                                            "\(subjectLead != nil && subjectLead?.firstName != nil ? "with \(subjectLead?.firstName ?? "Unknown")":"")"
                ), displayMode: .inline)
            }
        }
    }
}

#if DEBUG
struct MissedCallsView_Previews: PreviewProvider {
    static var previews: some View {
        let selectLead = Binding<IncomingLead?>(
            get: { nil }, set: { _ in }
        )
        MissedCallsView(
            subjectLead: selectLead
        )
    }
}
#endif
