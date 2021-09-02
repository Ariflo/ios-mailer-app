//
//  CallListView.swift
//  Addressable
//
//  Created by Ari on 12/30/20.
//

import SwiftUI

enum CallLabel: String, CaseIterable {
    case inbox, removals, spam
}

struct CallListView: View, Equatable {
    static func == (lhs: CallListView, rhs: CallListView) -> Bool {
        lhs.selectedMenuItem == rhs.selectedMenuItem &&
            lhs.displayInboxCalls == rhs.displayInboxCalls &&
            lhs.displayRemovalCalls == rhs.displayRemovalCalls &&
            lhs.displaySpamCalls == rhs.displaySpamCalls &&
            lhs.displayIncomingLeadSurvey == rhs.displayIncomingLeadSurvey
    }
    @EnvironmentObject var app: Application
    @ObservedObject var viewModel: CallsViewModel
    @Binding var selectedMenuItem: MainMenu
    @Binding var displayIncomingLeadSurvey: Bool
    @Binding var subjectLead: IncomingLead?

    @State var displayInboxCalls: Bool = true
    @State var displayRemovalCalls: Bool = false
    @State var displaySpamCalls: Bool = false

    init(viewModel: CallsViewModel, selectedMenuItem: Binding<MainMenu>, displayIncomingLeadSurvey: Binding<Bool>, lead: Binding<IncomingLead?>) {
        self.viewModel = viewModel
        self._selectedMenuItem = selectedMenuItem
        self._displayIncomingLeadSurvey = displayIncomingLeadSurvey
        self._subjectLead = lead

        self.viewModel.getLeads()
    }

    var body: some View {
        VStack {
            if viewModel.incomingLeads.isEmpty && !viewModel.loading {
                HStack {
                    Spacer()
                    Text("No Calls from Leads")
                    Spacer()
                }.frame(
                    minWidth: 0,
                    maxWidth: .infinity,
                    minHeight: 0,
                    maxHeight: .infinity,
                    alignment: .center
                )
            } else if viewModel.loading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .frame(
                        minWidth: 0,
                        maxWidth: .infinity,
                        minHeight: 0,
                        maxHeight: .infinity,
                        alignment: .center
                    )
            } else {
                RefreshableScrollView(refreshing: $viewModel.refreshIncomingLeadsData) {
                    ForEach(CallLabel.allCases, id: \.self) { callLabel in
                        CallListSectionHeaderView(
                            label: callLabel,
                            count: getLeads(for: callLabel, forCount: true).count,
                            displaySection: getDisplaySection(for: callLabel)
                        )
                        VStack(spacing: 0) {
                            ForEach(getLeads(for: callLabel)) { lead in
                                if let score = lead.qualityScore {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 6) {
                                            if let name = lead.firstName {
                                                Text("\(name.contains("unknown")  ? "Unknown Name" : name)")
                                                    .font(Font.custom("Silka-Bold", size: 18))
                                            }
                                            score > 0 ?
                                                Text(getTag(for: score))
                                                .font(Font.custom("Silka-Medium", size: 14)) :
                                                Text(lead.fromNumber ?? "Unknown Number")
                                                .font(Font.custom("Silka-Medium", size: 14))
                                            if callLabel == .inbox {
                                                Text(score > 0 ? "Update Tag" : "Tag Lead")
                                                    .font(Font.custom("Silka-Medium", size: 14))
                                                    .padding(8)
                                                    .multilineTextAlignment(.center)
                                                    .foregroundColor(Color.white)
                                                    .background(Color.addressablePurple)
                                                    .cornerRadius(5)
                                                    .onTapGesture {
                                                        subjectLead = lead
                                                        displayIncomingLeadSurvey = true
                                                    }
                                            }
                                            Text(lead.createdAt)
                                                .font(Font.custom("Silka-Medium", size: 14))
                                        }.padding(.vertical, 8)
                                        Spacer()
                                        if callLabel == .inbox {
                                            Image(systemName: "phone")
                                                .foregroundColor(Color.addressablePurple)
                                                .padding(.trailing, 20)
                                                .imageScale(.large)
                                                .onTapGesture {
                                                    app.verifyPermissions {
                                                        // In the case a user disallowed PN permissions on initial launch
                                                        // register for remote PN + Twilio here
                                                        DispatchQueue.main.async {
                                                            UIApplication.shared.registerForRemoteNotifications()
                                                        }
                                                        // Display Outgoing Call View
                                                        DispatchQueue.main.async {
                                                            app.currentView = .activeCall
                                                        }
                                                        guard let callManager = app.callManager else {
                                                            print("No CallManager to make phone call in CallListView")
                                                            return
                                                        }
                                                        callManager.getLatestIncomingLeadsList()
                                                        // Make outgoing call
                                                        callManager.startCall(to: lead)
                                                    }
                                                }
                                        } else {
                                            Image(systemName: "arrow.uturn.left")
                                                .foregroundColor(Color.addressablePurple)
                                                .padding(.trailing, 20)
                                                .imageScale(.large)
                                                .onTapGesture {
                                                    subjectLead = lead
                                                    displayIncomingLeadSurvey = true
                                                }
                                        }
                                    }
                                    .transition(.move(edge: .top))
                                    .padding(.horizontal)
                                    .padding(.vertical, 10)
                                    .background(Color.white)
                                    .border(width: 1, edges: [.bottom], color: Color.gray.opacity(0.2))
                                }
                            }
                        }
                    }
                }
            }
        }
        .background(Color.addressableLightGray)
    }
    private func getTag(for score: Int) -> String {
        switch score {
        case 1:
            return "Low Interest"
        case 2:
            return "Fair"
        case 3:
            return "Strong Lead"
        default:
            return "Untagged Lead"
        }
    }
    private func getDisplaySection(for callLabel: CallLabel) -> Binding<Bool> {
        switch callLabel {
        case .inbox:
            return $displayInboxCalls
        case .removals:
            return $displayRemovalCalls
        case .spam:
            return $displaySpamCalls
        }
    }
    private func getLeads(for label: CallLabel, forCount: Bool = false) -> [IncomingLead] {
        switch label {
        case .inbox:
            return viewModel.incomingLeads.filter { $0.status != "spam" &&
                $0.status != "removed" &&
                (displayInboxCalls || forCount)
            }
        case .removals:
            return viewModel.incomingLeads.filter { $0.status == "removed" && (displayRemovalCalls || forCount) }
        case .spam:
            return viewModel.incomingLeads.filter { $0.status == "spam" && (displaySpamCalls || forCount) }
        }
    }
}

#if DEBUG
struct CallListView_Previews: PreviewProvider {
    static var previews: some View {
        let selectedMenuItem = Binding<MainMenu>(
            get: { MainMenu.campaigns }, set: { _ in }
        )
        let displayIncomingLeadSurveyBinding = Binding<Bool>(
            get: { true }, set: { _ in }
        )
        let selectLead = Binding<IncomingLead?>(
            get: { nil }, set: { _ in }
        )
        CallListView(
            viewModel: CallsViewModel(provider: DependencyProvider()),
            selectedMenuItem: selectedMenuItem,
            displayIncomingLeadSurvey: displayIncomingLeadSurveyBinding,
            lead: selectLead
        )
    }
}
#endif
