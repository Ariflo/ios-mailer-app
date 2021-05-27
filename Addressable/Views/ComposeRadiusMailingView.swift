//
//  ComposeRadiusMailingView.swift
//  Addressable
//
//  Created by Ari on 2/11/21.
//

import SwiftUI
import GoogleMaps

// MARK: - ListEntryStatus
enum ListEntryStatus: String {
    case active, rejected, unavailable
}
// MARK: - ComposeRadiusMailingSteps
enum ComposeRadiusMailingSteps: String, CaseIterable {
    case selectLocation = "Location of Sale"
    case selectCard = "Choose Card"
    case chooseTopic = "Choose Campaign Type"
    case audienceProcessing = "Audience Processing"
    case confirmAudience = "Confirm Audience"
    case confirmSend = "Confirm and Send"
    case radiusSent = "Radius Mailing Sent"
}
// MARK: - ComposeRadiusMailingAlerts
enum ComposeRadiusMailingAlerts {
    case somethingWentWrong
}

// MARK: - ListStatus
enum ListStatus: String {
    case new
    case searching
    case searchFailed = "search_failed"
    case exporting
    case exportFailed = "export_failed"
    case ingesting
    case ingestFailed = "ingest_failed"
    case complete
}

// MARK: - MailingStatus
enum MailingStatus: String {
    case approved = "list_approved"
}

// MARK: - ComposeRadiusMailingView
struct ComposeRadiusMailingView: View {
    @EnvironmentObject var app: Application
    @ObservedObject var viewModel: ComposeRadiusMailingViewModel
    @State var showingAlert: Bool = false
    @State private var alertType: ComposeRadiusMailingAlerts = .somethingWentWrong

    init(viewModel: ComposeRadiusMailingViewModel) {
        self.viewModel = viewModel

        switch self.viewModel.touchOneMailing?.listStatus {
        case ListStatus.searching.rawValue,
             ListStatus.exporting.rawValue,
             ListStatus.ingesting.rawValue:
            self.viewModel.step = .selectCard
        case ListStatus.complete.rawValue:
            if (self.viewModel.touchOneMailing?.recipients.count)! > 0 {
                self.viewModel.step = .confirmAudience
            } else {
                self.viewModel.step = .selectLocation
            }
        default:
            self.viewModel.step = .selectLocation
        }
    }

    var body: some View {
        ZStack {
            VStack {
                // MARK: - BreadCrumbHeader
                HStack(alignment: .top) {
                    if let selectedMailingCoverId = viewModel.selectedCoverImageID,
                       let selectedCoverImage = viewModel.mailingCoverImages[selectedMailingCoverId] {
                        CustomNote.CoverImage(imageData: selectedCoverImage.imageData)
                            .frame(maxWidth: 100, maxHeight: 75)
                    } else {
                        Image("BlankCard")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 100, maxHeight: 75)
                    }
                    VStack(alignment: .leading, spacing: 11) {
                        Text("Building Radius Mailing").font(Font.custom("Silka-Medium", size: 12))
                        HStack {
                            if let currentStepIndex = Array(ComposeRadiusMailingSteps.allCases).firstIndex(of: viewModel.step) {
                                ForEach(Array(ComposeRadiusMailingSteps.allCases).indices, id: \.self) { index in
                                    if index <= currentStepIndex {
                                        generateCompletedStepCircleIndicator(for: currentStepIndex)
                                    } else {
                                        Circle().fill(Color.addressableLighterGray).frame(width: 9, height: 9)
                                    }
                                }
                            }
                        }
                    }.padding(.top, 12)
                }.padding()
                // MARK: - Main Menu
                VStack {
                    // MARK: - Main Menu Title Header
                    Text(viewModel.step.rawValue)
                        .font(Font.custom("Silka-Medium", size: 22))
                        .padding(.bottom)

                    switch viewModel.step {
                    case .selectLocation:
                        ComposeRadiusMailingSelectLocationView(viewModel: viewModel)
                    case .selectCard:
                        ComposeRadiusMailingCoverArtSelectionView(viewModel: viewModel)
                    case .chooseTopic:
                        ComposeRadiusMailingTopicSelectionView(viewModel: viewModel, showAlert: {
                            alertType = .somethingWentWrong
                            showingAlert = true
                        })
                    case .audienceProcessing:
                        ComposeRadiusMailingConfirmationView(
                            emptyMessage: "Our team is now building your mailing list. You will receive a notification when the list is ready for your review. Generally 24-48 hours."
                        )
                    case .confirmAudience:
                        ComposeRadiusMailingAudienceConfirmationView(viewModel: viewModel)
                    case .confirmSend:
                        ComposeRadiusMailingConfirmSendView(viewModel: viewModel)
                    case .radiusSent:
                        ComposeRadiusMailingConfirmationView(
                            emptyMessage: "Your Radius mailing is completed. You will receive a notification when the mailing is sent in the next 1-2 days."
                        )
                    }
                    // MARK: - Button Footer
                    HStack(spacing: 20) {
                        if viewModel.step != .confirmSend &&
                            viewModel.step != .radiusSent &&
                            viewModel.step != .audienceProcessing {
                            // MARK: - Back Button
                            Button(
                                action: {
                                    guard viewModel.step == .selectLocation ||
                                            viewModel.step == .audienceProcessing ||
                                            viewModel.step == .confirmAudience ||
                                            (isCurrentMailingListInProgress() && viewModel.step == .selectCard)
                                    else {
                                        viewModel.step.back()
                                        return
                                    }
                                    app.displayComposeRadiusMailing = false
                                }
                            ) {
                                Text(viewModel.step == .audienceProcessing ||
                                        viewModel.step == .confirmAudience ||
                                        (isCurrentMailingListInProgress() && viewModel.step == .selectCard) ? "Campaigns" : "Back")
                                    .font(Font.custom("Silka-Medium", size: 18))
                                    .frame(maxWidth: 140, maxHeight: 50)
                                    .foregroundColor(Color.addressableDarkGray)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 5)
                                            .stroke(Color.addressableDarkGray, lineWidth: 1)
                                    )
                            }
                        }
                        // MARK: - Next Button
                        Button(
                            action: {
                                guard viewModel.step != .audienceProcessing &&
                                        viewModel.step != .radiusSent else {
                                    app.displayComposeRadiusMailing = false
                                    return
                                }

                                if viewModel.step == .selectLocation && viewModel.touchOneMailing == nil {
                                    viewModel.createRadiusMailing { newMailing in
                                        guard newMailing != nil else { return }
                                    }
                                } else if viewModel.step == .selectLocation && viewModel.touchOneMailing != nil {
                                    viewModel.updateRadiusMailingData(for: .location) { updatedMailing in
                                        guard updatedMailing != nil else { return }
                                    }
                                }

                                if viewModel.step == .selectCard {
                                    viewModel.updateRadiusMailingData(for: .cover) { updatedMailing in
                                        guard updatedMailing != nil else { return }
                                    }
                                }

                                if viewModel.step == .chooseTopic {
                                    viewModel.updateRadiusMailingData(for: .topic) { updatedMailing in
                                        guard updatedMailing != nil else { return }
                                        if let mailingStatus = updatedMailing!.listStatus {
                                            if mailingStatus == ListStatus.complete.rawValue {
                                                viewModel.step = ComposeRadiusMailingSteps.confirmAudience
                                                return
                                            }
                                        }
                                    }
                                }

                                if viewModel.step == .confirmAudience {
                                    // Approve List + Create Touch 2 Mailing
                                    viewModel.updateRadiusMailingData(for: .list) { updatedMailing in
                                        guard updatedMailing != nil else { return }
                                    }
                                }

                                if viewModel.step == .confirmSend {
                                    viewModel.updateRadiusMailingData(for: .targetDate) { updatedMailing in
                                        guard updatedMailing != nil else { return }
                                    }
                                }
                                viewModel.step.next()
                            }
                        ) {
                            Text(getNextButtonText())
                                .font(Font.custom("Silka-Medium", size: 18))
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: viewModel.step == .confirmSend ||
                                        viewModel.step == .radiusSent ||
                                        viewModel.step == .audienceProcessing  ? 295 : 140, maxHeight: 50)
                                .foregroundColor(Color.white)
                                .background(Color.addressablePurple)
                                .cornerRadius(5)
                        }
                        .disabled(isNextButtonDisabled())
                        .opacity(isNextButtonDisabled() ? 0.4 : 1)
                    }
                }
                .padding(.vertical, 30)
                .background(Color.addressableLightGray)
                .border(width: 1, edges: [.top], color: Color.gray.opacity(0.2))
            }
            .onAppear {
                viewModel.getDataTreeDefaultSearchCriteria()
                viewModel.getRadiusMailingCoverImageOptions()
            }
            .alert(isPresented: $showingAlert) {
                switch alertType {
                case .somethingWentWrong:
                    return Alert(title: Text("Sorry something went wrong, try again or reach out to an Addressable representative if the problem persists."))
                }
            }
        }.edgesIgnoringSafeArea([.bottom])
    }

    private func getNextButtonText() -> String {
        switch viewModel.step {
        case .audienceProcessing:
            return "Finish"
        case .confirmSend:
            return "Confirm & Send"
        case .radiusSent:
            return "Complete"
        default:
            return "Next"
        }
    }

    private func isCurrentMailingListInProgress() -> Bool {
        switch self.viewModel.touchOneMailing?.listStatus {
        case ListStatus.searching.rawValue,
             ListStatus.exporting.rawValue,
             ListStatus.ingesting.rawValue:
            return true
        default:
            return false
        }
    }

    private func isNextButtonDisabled() -> Bool {
        switch viewModel.step {
        case .selectLocation:
            return viewModel.locationEntry.isEmpty
        case .selectCard:
            return viewModel.selectedCoverImageID == nil || viewModel.mailingCoverImages.isEmpty
        case .chooseTopic:
            return viewModel.topics.isEmpty || isMissingMergeVars()
        case .audienceProcessing:
            return false
        case.confirmAudience:
            return false
        case .confirmSend:
            return viewModel.isEditingTargetDropDate
        case .radiusSent:
            return false
        }
    }
    private func isMissingMergeVars() -> Bool {
        return (Array(viewModel.touchOneTemplateMergeVariables.keys).filter {
                    viewModel.touchOneTemplateMergeVariables[$0]!.isEmpty }.count > 0 ||
                    Array(viewModel.touchTwoTemplateMergeVariables.keys).filter {
                        viewModel.touchTwoTemplateMergeVariables[$0]!.isEmpty }.count > 0)
    }

    private func generateCompletedStepCircleIndicator(for index: Int?) -> some View {
        if let currentStepIndex = index {
            var count = currentStepIndex + 1

            while count > 0 {
                count -= 1
                return Circle().fill(Color.addressablePurple).frame(width: 9, height: 9)
            }
        }
        return Circle().fill(Color.addressableLighterGray).frame(width: 9, height: 9)
    }
}

struct ComposeRadiusMailingView_Previews: PreviewProvider {
    static var previews: some View {
        ComposeRadiusMailingView(viewModel: ComposeRadiusMailingViewModel(selectedRadiusMailing: nil))
    }
}

// MARK: - EmptyListView
struct EmptyListView: View {
    var message: String

    var body: some View {
        VStack(alignment: .center, spacing: 6) {
            Text(message)
                .font(Font.custom("Silka-Regular", size: 16))
                .padding(25)
                .multilineTextAlignment(.center)
        }
    }
}
