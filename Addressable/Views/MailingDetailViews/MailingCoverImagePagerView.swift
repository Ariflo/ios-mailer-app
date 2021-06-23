//
//  MailingCoverImagePagerView.swift
//  Addressable
//
//  Created by Ari on 6/16/21.
//

import SwiftUI

enum MailingImages: String, CaseIterable {
    case envelopeOutside = "Envelope"
    case cardFront = "Front"
    case cardInside = "Inside"
    case cardBack = "Back"
}

struct MailingCoverImagePagerView: View, Equatable {
    static func == (lhs: MailingCoverImagePagerView, rhs: MailingCoverImagePagerView) -> Bool {
        lhs.isEditingMailingCoverImage == rhs.isEditingMailingCoverImage &&
            lhs.viewModel.selectedFrontCoverImageData == rhs.viewModel.selectedFrontCoverImageData &&
            lhs.viewModel.selectedBackCoverImageData == rhs.viewModel.selectedBackCoverImageData
    }

    @ObservedObject var viewModel: MailingCoverImagePagerViewModel
    @Binding var isEditingMailing: Bool
    @Binding var selectedMailingImageIndex: Int
    @Binding var selectedCoverImageIndex: Int

    var isEditingMailingCoverImage: Bool = false

    init(
        viewModel: MailingCoverImagePagerViewModel,
        isEditingMailing: Binding<Bool>,
        selectedMailingImageIndex: Binding<Int>,
        isEditingMailingCoverImage: Bool,
        selectedCoverImageIndex: Binding<Int>
    ) {
        self.viewModel = viewModel
        self._isEditingMailing = isEditingMailing
        self.isEditingMailingCoverImage = isEditingMailingCoverImage
        self._selectedMailingImageIndex = selectedMailingImageIndex
        self._selectedCoverImageIndex = selectedCoverImageIndex
    }

    var body: some View {
        VStack(spacing: 0) {
            let mailingImages = isEditingMailingCoverImage ? MailingImages.allCases
                .filter { $0 == .cardBack || $0 == .cardFront } : MailingImages.allCases

            TabView(selection: isEditingMailingCoverImage ? $selectedCoverImageIndex : $selectedMailingImageIndex) {
                ForEach(mailingImages.indices) { index in
                    switch mailingImages[index] {
                    case .envelopeOutside:
                        MailingImagePreviewView(
                            imageData: viewModel.envelopeOutsideImageData,
                            refreshMailing: {
                                viewModel.refreshMailing()
                                viewModel.renderedImageType = mailingImages[index]
                            },
                            cancelRefreshMailingTask: {
                                viewModel.refreshMailingTask.cancel()
                            }
                        ).tag(index)
                    case .cardFront:
                        MailingImagePreviewView(
                            imageData: viewModel.selectedFrontCoverImageData ?? viewModel.cardFrontImageData,
                            refreshMailing: {
                                viewModel.refreshMailing()
                                viewModel.renderedImageType = mailingImages[index]
                            },
                            cancelRefreshMailingTask: {
                                viewModel.refreshMailingTask.cancel()
                            }
                        )
                        .tag(index)
                    case .cardInside:
                        MailingImagePreviewView(
                            imageData: viewModel.cardInsideImageData,
                            refreshMailing: {
                                viewModel.refreshMailing()
                                viewModel.renderedImageType = mailingImages[index]
                            },
                            cancelRefreshMailingTask: {
                                viewModel.refreshMailingTask.cancel()
                            }
                        ).tag(index)
                    case .cardBack:
                        MailingImagePreviewView(
                            imageData: viewModel.selectedBackCoverImageData ?? viewModel.cardBackImageData,
                            refreshMailing: {
                                viewModel.refreshMailing()
                                viewModel.renderedImageType = mailingImages[index]
                            },
                            cancelRefreshMailingTask: {
                                viewModel.refreshMailingTask.cancel()
                            }
                        )
                        .tag(index)
                    }
                }
            }
            .tabViewStyle(
                PageTabViewStyle(
                    indexDisplayMode: isEditingMailing && !isEditingMailingCoverImage ? .never : .automatic
                )
            )
            .disabled(isEditingMailing && !isEditingMailingCoverImage)
            .frame(maxHeight: isEditingMailing ? 165 : .infinity)
            .id(mailingImages)
            // MARK: - Pager Label + Edit Button
            VStack(spacing: 8) {
                !isEditingMailing || isEditingMailingCoverImage ?
                    Text(getLabel())
                    .font(Font.custom("Silka-Medium", size: 16))
                    .foregroundColor(Color.black.opacity(0.8)) : nil
                !isEditingMailing ? Button(action: {
                    withAnimation(.easeIn(duration: 0.5)) {
                        isEditingMailing.toggle()
                    }
                }) {
                    Text(getEditButtonText(for: mailingImages[
                        isEditingMailingCoverImage ? selectedCoverImageIndex : selectedMailingImageIndex
                    ]))
                    .font(Font.custom("Silka-Bold", size: 12))
                    .foregroundColor(Color.black.opacity(0.3))
                    .underline()
                }
                .disabled(getMailingStatus() == .mailed || getMailingStatus() == .processing)
                .opacity(getMailingStatus() == .mailed || getMailingStatus() == .processing ? 0.4 : 1) : nil
            }
        }.onAppear {
            if viewModel.envelopeOutsideImageData == nil ||
                viewModel.cardFrontImageData == nil ||
                viewModel.cardInsideImageData == nil ||
                viewModel.cardBackImageData == nil {
                viewModel.getMailingImages()
            }
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
    private func getEditButtonText(for mailingImage: MailingImages) -> String {
        switch mailingImage {
        case .envelopeOutside:
            return "Edit Return Address"
        case .cardFront,
             .cardBack:
            return "Change Card"
        case .cardInside:
            return "Edit Text"
        }
    }
    private func getLabel() -> String {
        return isEditingMailingCoverImage ? MailingImages.allCases.filter {
            $0 == .cardBack || $0 == .cardFront
        }[selectedCoverImageIndex].rawValue : MailingImages.allCases[selectedMailingImageIndex].rawValue
    }
}
