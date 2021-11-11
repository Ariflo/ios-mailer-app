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
    @State var addNote: Bool = false
    let taggingComplete: () -> Void

    init(viewModel: TagIncomingLeadViewModel, taggingComplete: @escaping () -> Void) {
        self.viewModel = viewModel
        self.taggingComplete = taggingComplete
    }

    var body: some View {
        let isRealOrSpamSegmentView = CustomSegmentedPickerView(
            viewModel: viewModel,
            tagOptions: [.person, .spam]
        ).environmentObject(app)

        let isInterestedSegmentView = CustomSegmentedPickerView(
            viewModel: viewModel,
            tagOptions: [.lowInterest, .fair, .lead]
        ).environmentObject(app)

        let isRemovalSegmentView = CustomSegmentedPickerView(
            viewModel: viewModel,
            tagOptions: [.removeNo, .removeYes]
        ).environmentObject(app)

        ScrollView {
            ZStack(alignment: .top) {
                Color.white.edgesIgnoringSafeArea(.all)
                VStack(alignment: .leading, spacing: 25) {
                    HStack {
                        Button(
                            action: {
                                if let lead = viewModel.subjectLead {
                                    viewModel.tagIncomingLead(for: lead.id) { taggedLead in
                                        guard taggedLead != nil else {
                                            print("Unable to tagIncomingLead() in TagIncomingLeadView")
                                            return
                                        }
                                        taggingComplete()
                                        viewModel.analyticsTracker.trackEvent(
                                            .mobileLeadTagged,
                                            context: app.persistentContainer.viewContext
                                        )
                                    }
                                } else {
                                    print("No subjectLead to tag")
                                }
                            }
                        ) {
                            Text("Save")
                        }
                        Spacer()
                        if let callerID = app.callManager?.currentCallerID.caller {
                            Text("Tag your call with \(callerID)")
                                .font(Font.custom("Silka-Bold", size: 16))
                                .multilineTextAlignment(.center)
                        } else {
                            Text("Tag Your Last Caller")
                                .font(Font.custom("Silka-Bold", size: 16))
                                .multilineTextAlignment(.center)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color.addressableLightGray)
                    .border(width: 1, edges: [.bottom], color: Color.gray.opacity(0.2))

                    viewModel.isRemovalSelectedTag != .removeYes ?
                        VStack(alignment: .leading) {
                            Text("This caller was:")
                                .font(Font.custom("Silka-Medium", size: 14))
                            isRealOrSpamSegmentView
                        }.padding() : nil

                    viewModel.isRealOrSpamSelectedTag != .spam && viewModel.isRemovalSelectedTag == .removeNo ?
                        VStack(alignment: .leading) {
                            Text("How good of a contact is this?")
                                .font(Font.custom("Silka-Medium", size: 14))
                            isInterestedSegmentView
                        }.padding() : nil

                    viewModel.isRealOrSpamSelectedTag != .spam ? VStack(alignment: .center) {
                        Text("Did they request to be removed from the mailing list?")
                            .font(Font.custom("Silka-Medium", size: 14))
                            .multilineTextAlignment(.center)
                            .padding()
                        isRemovalSegmentView
                    } : nil

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes")
                            .font(Font.custom("Silka-Medium", size: 14))
                            .padding(.horizontal, 12)
                        ForEach(viewModel.leadNotes) { userNote in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(userNote.userName)
                                        .font(Font.custom("Silka-Bold", size: 12))
                                    Text("[\(userNote.createdAt)]")
                                        .font(Font.custom("Silka-Medium", size: 12))
                                }
                                Spacer()
                                Text(userNote.note)
                                    .font(Font.custom("Silka-Regular", size: 12))
                                    .padding(.trailing, 12)
                            }
                            .padding(.horizontal, 12)
                        }
                        addNote ?
                            MultilineTextView(text: $viewModel.userNotes)
                            .modifier(TextFieldModifier())
                            .padding(.horizontal, 12)
                            : nil
                    }
                    HStack(spacing: 12) {
                        Spacer()
                        addNote ? Text("Cancel")
                            .font(Font.custom("Silka-Medium", size: 14))
                            .padding(8)
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color.addressableDarkGray)
                            .cornerRadius(5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.addressableDarkGray, lineWidth: 1)
                            )
                            .onTapGesture {
                                addNote = false
                            } : nil
                        Text(addNote ? "Save" : "Add Note")
                            .font(Font.custom("Silka-Medium", size: 14))
                            .padding(8)
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color.white)
                            .background(Color.addressablePurple)
                            .cornerRadius(5)
                            .onTapGesture {
                                if !addNote {
                                    addNote = true
                                } else {
                                    viewModel.saveUserNote { updatedLead in
                                        guard updatedLead != nil else { return }
                                        viewModel.analyticsTracker.trackEvent(
                                            .mobileUserNoteSaved,
                                            context: app.persistentContainer.viewContext
                                        )
                                        addNote = false
                                    }
                                }
                            }
                        Spacer()
                    }
                }
            }
        }
        .onDisappear {
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
