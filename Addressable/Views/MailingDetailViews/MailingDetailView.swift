//
//  MailingDetailView.swift
//  Addressable
//
//  Created by Ari on 6/7/21.
//

import SwiftUI

enum SettingsMenu: String, CaseIterable {
    case cancelMailing = "Cancel Mailing"
}

struct MailingDetailView: View, Equatable {
    static func == (lhs: MailingDetailView, rhs: MailingDetailView) -> Bool {
        lhs.viewModel.mailing == rhs.viewModel.mailing
    }

    @EnvironmentObject var app: Application
    @ObservedObject var viewModel: MailingDetailViewModel

    @State var isEditingMailing: Bool = false
    @State var selectedMailingImageIndex: Int = 0
    @State var selectedCoverImageIndex: Int = 0

    @State var isShowingInsideCardEditAlert: Bool = false

    init(viewModel: MailingDetailViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: - Mailing Name Header
            HStack {
                Text(viewModel.mailing.name)
                    .font(Font.custom("Silka-Medium", size: 14))
                    .foregroundColor(Color.addressablePurple)
                    .padding(.vertical)
                Spacer()
                Text(getMailingStatus().rawValue)
                    .font(Font.custom("Silka-Medium", size: 12))
                    .foregroundColor(Color.black)
                    .padding(.vertical)
            }
            .padding(.horizontal, 20)
            .border(width: 1, edges: [.bottom], color: Color.gray.opacity(0.2))
            .background(Color.white)
            // MARK: - Mailing Date and Size Header
            HStack {
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
                //                Menu {
                //                    ForEach(SettingsMenu.allCases, id: \.self) { menuOption in
                //                        Button {
                //                            // Open Setting Option Menu
                //                        } label: {
                //                            Text(menuOption.rawValue).font(Font.custom("Silka-Medium", size: 14))
                //                        }
                //                    }
                //                } label: {
                //                    Image(systemName: "gear")
                //                        .imageScale(.medium)
                //                        .foregroundColor(Color.black.opacity(0.5))
                //                }
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
