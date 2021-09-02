//
//  MailingDetailView.swift
//  Addressable
//
//  Created by Ari on 6/7/21.
//

import SwiftUI

enum SettingsMenu: String, CaseIterable {
    case sendMailing = "Send Mailing"
    case addTokens = "Purchase Tokens"
    case revert = "Revert to Draft"
    case sendAgain = "Send Again"
    case clone = "Clone"
    case cancelMailing = "Cancel Mailing"
}

enum MailingDetailAlertTypes {
    case confirmCancelEdit, confirmCancelMailing, mailingError, addTokensAlert
}

enum MailingDetailSheetTypes: Identifiable {
    case confirmAndSendMailing, cloneMailing, addMessageTemplate, addAudience

    var id: Int {
        hashValue
    }
}

// swiftlint:disable type_body_length
struct MailingDetailView: View, Equatable {
    static func == (lhs: MailingDetailView, rhs: MailingDetailView) -> Bool {
        lhs.viewModel.mailing == rhs.viewModel.mailing
    }

    @EnvironmentObject var app: Application
    @ObservedObject var viewModel: MailingDetailViewModel

    @State var isEditingMailing: Bool = false
    @State var expandMailingList: Bool = false
    @State var shrinkMailingList: Bool = false
    @State var selectedMailingImageIndex: Int = 0
    @State var selectedCoverImageIndex: Int = 0
    @State var isShowingAlert: Bool = false
    @State var alertType: MailingDetailAlertTypes = .confirmCancelMailing
    @State var activeSheetType: MailingDetailSheetTypes?

    init(viewModel: MailingDetailViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: - Mailing Name Header
            HStack {
                if let mailingName = viewModel.mailing.subjectListEntry?.siteAddressLine1 {
                    Text(mailingName)
                        .font(Font.custom("Silka-Medium", size: 14))
                        .foregroundColor(Color.addressablePurple)
                        .padding(.vertical)
                } else {
                    Text(viewModel.mailing.name)
                        .font(Font.custom("Silka-Medium", size: 14))
                        .foregroundColor(Color.addressablePurple)
                        .padding(.vertical)
                }
                viewModel.mailing.type == MailingType.radius.rawValue ?
                    Text("Touch \(isTouchTwoMailing() ? "2" : "1")")
                    .font(Font.custom("Silka-Regular", size: 12))
                    .foregroundColor(Color.addressableFadedBlack)
                    .padding(.vertical) : nil
                Spacer()
                Text(getMailingStatus().rawValue)
                    .font(Font.custom("Silka-Medium", size: 12))
                    .foregroundColor(Color.black)
                    .padding(.vertical)
            }
            .padding(.horizontal, 20)
            .border(width: 1, edges: [.bottom], color: Color.gray.opacity(0.2))
            .background(Color.white)
            HStack {
                // MARK: - Mailing Date and Size Header
                Text("Mailing on: \(getFormattedTargetDropDate())")
                    .font(Font.custom("Silka-Medium", size: 14))
                    .foregroundColor(Color.black.opacity(0.8))
                    .padding(.vertical)
                Spacer()
                Text("size: \(viewModel.mailing.targetQuantity)")
                    .font(Font.custom("Silka-Medium", size: 12))
                    .foregroundColor(Color.black.opacity(0.8))
                    .padding(.vertical)
                Spacer()
                // MARK: - Mailing Settings Menu
                let mailingProcessing = getMailingStatus() == .processing &&
                    viewModel.mailing.mailingStatus != MailingState.productionReady.rawValue
                Menu {
                    ForEach(SettingsMenu.allCases, id: \.self) { menuOption in
                        if shouldDisplay(menuOption) {
                            Button {
                                triggerAction(for: menuOption)
                            } label: {
                                Text(menuOption.rawValue).font(Font.custom("Silka-Medium", size: 14))
                            }
                        }
                    }
                } label: {
                    if mailingProcessing {
                        Text("Mailing Processing...")
                            .font(Font.custom("Silka-Medium", size: 14))
                    } else if getMailingStatus() != .archived {
                        Image(systemName: "gear")
                            .imageScale(.medium)
                            .foregroundColor(Color.black.opacity(0.5))
                    }
                }
                .disabled(mailingProcessing)
                .opacity(mailingProcessing ? 0.6 : 1)
            }
            .padding(.horizontal, 20)
            .border(width: 1, edges: [.bottom], color: Color.gray.opacity(0.2))
            .background(Color.white)
            // MARK: - Mailing Details Main Menu
            VStack(spacing: 12) {
                let isEditingReturnAddress = isEditingMailing &&
                    MailingImages.allCases[selectedMailingImageIndex] == .envelopeOutside
                let isEditingFrontCardCover = isEditingMailing &&
                    MailingImages.allCases[selectedMailingImageIndex] == .cardFront
                let isEditingBackCardCover = isEditingMailing &&
                    MailingImages.allCases[selectedMailingImageIndex] == .cardBack

                let drag = DragGesture()
                    .onEnded {
                        if $0.translation.height > 0 {
                            withAnimation {
                                if !self.shrinkMailingList && !self.expandMailingList {
                                    self.shrinkMailingList.toggle()
                                } else {
                                    self.shrinkMailingList = false
                                    self.expandMailingList = false
                                }
                            }
                        } else {
                            withAnimation {
                                if !self.shrinkMailingList && !self.expandMailingList {
                                    self.expandMailingList.toggle()
                                } else {
                                    self.shrinkMailingList = false
                                    self.expandMailingList = false
                                }
                            }
                        }
                    }
                // MARK: - MailingCoverImagePagerView
                isEditingReturnAddress ? nil :
                    MailingCoverImagePagerView(
                        viewModel: MailingCoverImagePagerViewModel(
                            provider: app.dependencyProvider,
                            selectedMailing: $viewModel.mailing,
                            selectedFrontImageData: $viewModel.selectedFrontImageData,
                            selectedBackImageData: $viewModel.selectedBackImageData,
                            selecteImageId: viewModel.selectedImageId
                        ),
                        isEditingMailing: $isEditingMailing,
                        minimizePagerView: $expandMailingList,
                        maximizePagerView: $shrinkMailingList,
                        selectedMailingImageIndex: $selectedMailingImageIndex,
                        isEditingMailingCoverImage: isEditingFrontCardCover || isEditingBackCardCover,
                        selectedCoverImageIndex: $selectedCoverImageIndex,
                        activeSheetType: $activeSheetType
                    )
                    .equatable()
                    .environmentObject(app)
                // MARK: - EditReturnAddressView
                isEditingReturnAddress ?
                    EditReturnAddressView(
                        viewModel: EditReturnAddressViewModel(
                            provider: app.dependencyProvider,
                            selectedMailing: $viewModel.mailing
                        ),
                        isEditingReturnAddress: $isEditingMailing
                    )
                    .padding(20)
                    .transition(.move(edge: .top)) : nil
                // MARK: - MailingRecipientsListView
                isEditingBackCardCover ||
                    isEditingFrontCardCover ? nil :
                    MailingRecipientsListView(
                        viewModel: MailingRecipientsListViewModel(
                            provider: app.dependencyProvider,
                            selectedMailing: $viewModel.mailing,
                            numActiveRecipients: $viewModel.numActiveRecipients
                        ),
                        activeSheetType: $activeSheetType
                    )
                    .equatable()
                    .padding(.horizontal, 20)
                    .disabled(isEditingMailing)
                    .opacity(isEditingMailing ? 0.5 : 1)
                    .overlay(
                        isEditingMailing ?
                            Rectangle()
                            .fill(Color.addressableFadedBlack)
                            .opacity(isEditingMailing ? 0.5 : 1)
                            : nil
                    )
                    .gesture(drag)
                // MARK: - MailingCoverImageGalleryView
                isEditingFrontCardCover || isEditingBackCardCover ?
                    MailingCoverImageGalleryView(
                        viewModel: MailingCoverImageGalleryViewModel(
                            provider: app.dependencyProvider,
                            selectedMailing: $viewModel.mailing,
                            selectedFrontImageData: $viewModel.selectedFrontImageData,
                            selectedBackImageData: $viewModel.selectedBackImageData,
                            selectedImageId: $viewModel.selectedImageId
                        ),
                        isEditingMailing: $isEditingMailing,
                        isEditingBackCardCover: isEditingBackCardCover || selectedCoverImageIndex > 0
                    )
                    .equatable()
                    .padding(20)
                    .transition(.move(edge: .bottom)) : nil
            }
        }
        .sheet(item: $activeSheetType) { item in
            switch item {
            case .confirmAndSendMailing:
                ConfirmAndSendMailingView(
                    viewModel: ConfirmAndSendMailingViewModel(
                        provider: app.dependencyProvider,
                        selectedMailing: $viewModel.mailing
                    ),
                    isMailingReady: viewModel.numActiveRecipients > 0 &&
                        viewModel.mailing.layoutTemplate != nil &&
                        (viewModel.mailing.customNoteTemplateID != nil &&
                            viewModel.mailing.customNoteBody != nil)
                )
            case .cloneMailing:
                CloneMailingView(
                    viewModel: CloneMailingViewModel(
                        provider: app.dependencyProvider,
                        selectedMailing: $viewModel.mailing
                    )
                )
            case .addMessageTemplate:
                MessageTemplateSelectionView(
                    viewModel: MessageTemplateSelectionViewModel(
                        provider: app.dependencyProvider,
                        selectedMailing: $viewModel.mailing
                    )
                ).equatable()
            case .addAudience:
                SelectAudienceView(
                    viewModel: SelectAudienceViewModel(
                        provider: app.dependencyProvider,
                        selectedMailing: $viewModel.mailing)
                )
            }
        }
        .alert(isPresented: $isShowingAlert) {
            switch alertType {
            case .confirmCancelEdit:
                return Alert(
                    title: Text("Cancel Edit")
                        .font(Font.custom("Silka-Bold", size: 14)),
                    message: Text("Want to undo your recent changes?")
                        .font(Font.custom("Silka-Medium", size: 12)),
                    primaryButton: .default(Text("Confirm")) {
                        withAnimation(.easeOut(duration: 0.5)) {
                            isEditingMailing = false
                        }
                    }, secondaryButton: .cancel())
            case .confirmCancelMailing:
                return Alert(
                    title: Text("Cancel '\(viewModel.mailing.name) \(getTouchNumber())'?")
                        .font(Font.custom("Silka-Bold", size: 14)),
                    message: Text("Do you want to cancel and remove this mailing from the production queue?")
                        .font(Font.custom("Silka-Medium", size: 12)),
                    primaryButton: .default(Text("Yes, Refund Tokens")) {
                        viewModel.cancelMailing { updatedMailing in
                            if let refundedMailing = updatedMailing {
                                viewModel.mailing = refundedMailing
                                isShowingAlert = false
                            } else {
                                alertType = .mailingError
                                isShowingAlert = true
                            }
                        }
                    }, secondaryButton: .cancel())
            case .mailingError:
                return Alert(title: Text("Sorry something went wrong, " +
                                            "try again or reach out to an Addressable " +
                                            "representative if the problem persists."))
            case .addTokensAlert:
                return Alert(title: Text("Please visit the 'Settings' section " +
                                            "of the Addressable.app portal to buy more tokens and send this mailing."))
            }
        }
        .background(Color.addressableLightGray)
    }
    private func shouldDisplay(_ option: SettingsMenu) -> Bool {
        for state in MailingState.allCases where state.rawValue == viewModel.mailing.mailingStatus {
            switch option {
            case .sendMailing:
                return state == .draft || state == .listReady || state == .listAdded || state == .listApproved
            case .addTokens:
                return state == .pending
            case .revert:
                return state == .productionReady
            case .sendAgain:
                return state == .mailed
            case .clone:
                return state == .canceled
            case .cancelMailing:
                return state == .scheduled
            }
        }
        return false
    }
    private func triggerAction(for menuOption: SettingsMenu) {
        switch menuOption {
        case .sendMailing:
            activeSheetType = .confirmAndSendMailing
        case .revert,
             .cancelMailing:
            isShowingAlert = true
        case .addTokens:
            isShowingAlert = true
            alertType = .addTokensAlert
        case .clone,
             .sendAgain:
            activeSheetType = .cloneMailing
        }
    }
    private func getMailingStatus() -> MailingStatus {
        switch viewModel.mailing.mailingStatus {
        case MailingState.mailed.rawValue,
             MailingState.remailed.rawValue:
            return MailingStatus.mailed
        case MailingState.production.rawValue,
             MailingState.printReady.rawValue,
             MailingState.printing.rawValue,
             MailingState.writeReady.rawValue,
             MailingState.writing.rawValue,
             MailingState.mailReady.rawValue,
             MailingState.productionReady.rawValue:
            return MailingStatus.processing
        case MailingState.scheduled.rawValue:
            return MailingStatus.upcoming
        case MailingState.listReady.rawValue,
             MailingState.listAdded.rawValue,
             MailingState.listApproved.rawValue,
             MailingState.draft.rawValue:
            return MailingStatus.draft
        case MailingState.delivered.rawValue,
             MailingState.archived.rawValue:
            return MailingStatus.archived
        default:
            return MailingStatus.canceled
        }
    }
    private func getFormattedTargetDropDate() -> String {
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "MMM dd"

        return dateFormatterPrint.string(from: getTargetDropDateObject())
    }
    private func getTargetDropDateObject() -> Date {
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "yyyy-MM-dd"
        if let date = dateFormatterGet.date(from: viewModel.mailing.targetDropDate) {
            return date
        } else {
            return Date()
        }
    }
    private func isTouchTwoMailing() -> Bool {
        if let relatedTouchMailing = viewModel.mailing.relatedMailing {
            return relatedTouchMailing.parentMailingID == nil
        } else {
            return false
        }
    }
    private func getTouchNumber() -> String {
        return viewModel.mailing.type == MailingType.radius.rawValue ? "| Touch \(isTouchTwoMailing() ? "2" : "1")" : ""
    }
}
