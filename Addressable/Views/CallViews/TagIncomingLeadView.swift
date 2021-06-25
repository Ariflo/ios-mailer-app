//
//  TagIncomingLeadView.swift
//  Addressable
//
//  Created by Ari on 3/4/21.
//

import SwiftUI

enum IncomingLeadTagOptions: String {
    case spam = "SPAM / Robot"
    case person = "Real Person"
    case lowInterest = "Low Interest"
    case fair = "Fair"
    case lead = "Strong Lead"
    case removeYes = "Yes"
    case removeNo = "No"
}

struct TagIncomingLeadView: View {
    @EnvironmentObject var app: Application
    @ObservedObject var viewModel: TagIncomingLeadViewModel
    let taggingComplete: () -> Void

    init(viewModel: TagIncomingLeadViewModel, taggingComplete: @escaping () -> Void) {
        self.viewModel = viewModel
        self.taggingComplete = taggingComplete
    }

    var body: some View {
        let isRealOrSpamSegmentView = CustomSegmentedPickerView(viewModel: viewModel, tagOptions: [.person, .spam])

        let isInterestedSegmentView = CustomSegmentedPickerView(viewModel: viewModel,
                                                                tagOptions: [.lowInterest, .fair, .lead])

        let isRemovalSegmentView = CustomSegmentedPickerView(viewModel: viewModel, tagOptions: [.removeNo, .removeYes])

        ZStack(alignment: .top) {
            Color.white.edgesIgnoringSafeArea(.all)

            VStack(alignment: .leading, spacing: 25) {
                Button(
                    action: {
                        if let callManager = app.callManager,
                           let knownLead = callManager.getLeadFromLatestCall() {
                            viewModel.tagIncomingLead(for: knownLead.id) { taggedLead in
                                guard taggedLead != nil else {
                                    print("Unable to tagIncomingLead() in TagIncomingLeadView")
                                    return
                                }
                                taggingComplete()
                            }
                        } else if viewModel.subjectLead != nil {
                            // swiftlint:disable force_unwrapping
                            viewModel.tagIncomingLead(for: viewModel.subjectLead!.id) { taggedLead in
                                guard taggedLead != nil else {
                                    print("Unable to tagIncomingLead() in TagIncomingLeadView")
                                    return
                                }
                                taggingComplete()
                            }
                        }
                    }
                ) {
                    Text("Save")
                }.padding()

                if let callerID = app.callManager?.currentCallerID.caller {
                    Text("Tag your call with \(callerID)")
                        .font(.title2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                } else {
                    Text("Tag Your Last Caller")
                        .font(.title2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }

                viewModel.isRemovalSelectedTag != .removeYes ?
                    VStack(alignment: .leading) {
                        Text("This caller was:")
                        isRealOrSpamSegmentView
                    }.padding() : nil

                viewModel.isRealOrSpamSelectedTag != .spam && viewModel.isRemovalSelectedTag == .removeNo ?
                    VStack(alignment: .leading) {
                        Text("How good of a contact is this?")
                        isInterestedSegmentView
                    }.padding() : nil

                viewModel.isRealOrSpamSelectedTag != .spam ?                 VStack(alignment: .center) {
                    Text("Did they request to be removed from the mailing list?")
                        .multilineTextAlignment(.center)
                        .padding()
                    isRemovalSegmentView
                } : nil
            }
        }.onDisappear {
            if let callManager = app.callManager {
                guard let relatedCall = callManager.currentActiveCall else {
                    print("No relatedCall to resetActiveCallState() in TagIncomingLeadView")
                    return
                }
                callManager.resetActiveCallState(for: relatedCall.uuid)
            }
        }
    }
}

#if DEBUG
struct TagIncomingLeadView_Previews: PreviewProvider {
    static var previews: some View {
        let selectLead = Binding<IncomingLead?>(
            get: { nil }, set: { _ in }
        )
        TagIncomingLeadView(
            viewModel: TagIncomingLeadViewModel(
                provider: DependencyProvider(), lead: selectLead
            )) {}.environmentObject(Application())
    }
}
#endif
