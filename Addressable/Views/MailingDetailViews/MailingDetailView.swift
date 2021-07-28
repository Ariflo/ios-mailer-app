//
//  MailingDetailView.swift
//  Addressable
//
//  Created by Ari on 6/7/21.
//

import SwiftUI

enum SettingsMenu: String, CaseIterable {
    case sendMailing = "Send Mailing"
    case addTokens = "Add Tokens"
    case revert = "Revert to Draft"
    case sendAgain = "Send Again"
    case results = "Results"
    case clone = "Clone"
    case cancelMailing = "Cancel Mailing"
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
    @State var selectedMailingImageIndex: Int = 0
    @State var selectedCoverImageIndex: Int = 0
    @State var displayConfirmationSheet: Bool = false

    @State var isShowingInsideCardEditAlert: Bool = false

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
                Text("size: \(viewModel.mailing.activeRecipientCount)")
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
                    } else {
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
                let isEditingInsideCard = isEditingMailing &&
                    MailingImages.allCases[selectedMailingImageIndex] == .cardInside
                let isEditingBackCardCover = isEditingMailing &&
                    MailingImages.allCases[selectedMailingImageIndex] == .cardBack

                let drag = DragGesture()
                    .onEnded { _ in
                        withAnimation {
                            self.expandMailingList.toggle()
                        }
                    }

                // MARK: - MailingCoverImagePagerView
                isEditingInsideCard || isEditingReturnAddress ? nil :
                    MailingCoverImagePagerView(
                        viewModel: MailingCoverImagePagerViewModel(
                            provider: app.dependencyProvider,
                            selectedMailing: viewModel.mailing,
                            selectedFrontImageData: $viewModel.selectedFrontImageData,
                            selectedBackImageData: $viewModel.selectedBackImageData,
                            selecteImageId: viewModel.selectedImageId
                        ),
                        isEditingMailing: $isEditingMailing,
                        minimizePagerView: $expandMailingList,
                        selectedMailingImageIndex: $selectedMailingImageIndex,
                        isEditingMailingCoverImage: isEditingFrontCardCover || isEditingBackCardCover,
                        selectedCoverImageIndex: $selectedCoverImageIndex
                    ).equatable()
                // MARK: - EditReturnAddressView
                isEditingReturnAddress ?
                    EditReturnAddressView(
                        viewModel: EditReturnAddressViewModel(
                            provider: app.dependencyProvider,
                            selectedMailing: viewModel.mailing
                        ),
                        isEditingReturnAddress: $isEditingMailing
                    )
                    .padding(20)
                    .transition(.move(edge: .top)) : nil
                // MARK: - MailingRecipientsListView
                isEditingInsideCard || isEditingBackCardCover || isEditingFrontCardCover ? nil :
                    MailingRecipientsListView(
                        viewModel: MailingRecipientsListViewModel(
                            provider: app.dependencyProvider,
                            selectedMailing: viewModel.mailing
                        )
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
                            selectedMailing: viewModel.mailing,
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


                // MARK: - EditMailingInsideCardView
                if let templateId = viewModel.mailing.customNoteTemplateID {
                    isEditingInsideCard ?
                        EditMailingInsideCardView(
                            viewModel: EditMailingInsideCardViewModel(
                                provider: app.dependencyProvider,
                                templateId: templateId
                            ),
                            isEditingMailing: $isEditingMailing,
                            isShowingInsideCardEditAlert: $isShowingInsideCardEditAlert
                        )
                        .equatable()
                        .transition(.move(edge: .bottom)) : nil
                }
            }
        }
        .sheet(isPresented: $displayConfirmationSheet) {
            ConfirmAndSendMailingView(
                viewModel: ConfirmAndSendMailingViewModel(
                    provider: app.dependencyProvider,
                    selectedMailing: $viewModel.mailing
                )
            )
        }
        .alert(isPresented: $isShowingInsideCardEditAlert) {
            Alert(
                title: Text("Cancel Edit")
                    .font(Font.custom("Silka-Bold", size: 14)),
                message: Text("Want to undo your recent changes?")
                    .font(Font.custom("Silka-Medium", size: 12)),
                primaryButton: .default(Text("Confirm")) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        isEditingMailing = false
                    }
                }, secondaryButton: .cancel())
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
            case .results:
                return state == .delivered || state == .archived
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
            displayConfirmationSheet = true
        //        case .addTokens:
        //            <#code#>
        //        case .revert:
        //            <#code#>
        //        case .sendAgain:
        //            <#code#>
        //        case .results:
        //            <#code#>
        //        case .clone:
        //            <#code#>
        //        case .cancelMailing:
        //            <#code#>
        default:
            break
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
        default:
            return MailingStatus.archived
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
}
