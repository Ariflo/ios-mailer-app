//
//  MailingCoverImageGalleryView.swift
//  Addressable
//
//  Created by Ari on 6/16/21.
//

import SwiftUI

struct MailingCoverImageGalleryView: View, Equatable {
    static func == (lhs: MailingCoverImageGalleryView, rhs: MailingCoverImageGalleryView) -> Bool {
        lhs.viewModel.mailing == rhs.viewModel.mailing
    }

    @EnvironmentObject var app: Application
    @ObservedObject var viewModel: MailingCoverImageGalleryViewModel
    @Binding var isEditingMailing: Bool

    var isEditingBackCardCover: Bool

    init(
        viewModel: MailingCoverImageGalleryViewModel,
        isEditingMailing: Binding<Bool>,
        isEditingBackCardCover: Bool
    ) {
        self.viewModel = viewModel
        self._isEditingMailing = isEditingMailing
        self.isEditingBackCardCover = isEditingBackCardCover
    }

    var body: some View {
        VStack(alignment: .center, spacing: 24) {
            // MARK: - Card Selection Buttons
            HStack(spacing: 12) {
                Button(action: {
                    withAnimation(.easeOut(duration: 0.5)) {
                        isEditingMailing = false
                        // Reset Any Unsaved changes
                        viewModel.selectedFrontCoverImageData = nil
                        viewModel.selectedBackCoverImageData = nil
                        viewModel.selectedCoverImageId = 0
                    }
                }) {
                    Text("Cancel")
                        .font(Font.custom("Silka-Medium", size: 16))
                        .frame(minWidth: 145, minHeight: 40)
                        .foregroundColor(Color.addressableDarkGray)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.addressableDarkGray, lineWidth: 1)
                        )
                }
                Spacer()
                Button(action: {
                    withAnimation(.easeOut(duration: 0.5)) {
                        isEditingMailing = false
                        viewModel.updateMailingCoverImage { updatedMailing in
                            if let mailing = updatedMailing {
                                viewModel.mailing = mailing
                                isEditingMailing = false
                                // Reset Any Unsaved changes
                                viewModel.selectedFrontCoverImageData = nil
                                viewModel.selectedBackCoverImageData = nil
                                viewModel.selectedCoverImageId = 0

                                viewModel.analyticsTracker.trackEvent(
                                    .mobileUpdatedCardImage,
                                    context: app.persistentContainer.viewContext
                                )
                            }
                        }
                    }
                }) {
                    Text("Use This Card")
                        .font(Font.custom("Silka-Medium", size: 16))
                        .multilineTextAlignment(.center)
                        .frame(minWidth: 145, minHeight: 40)
                        .foregroundColor(Color.white)
                        .background(Color.addressablePurple)
                        .cornerRadius(5)
                }
            }
            // MARK: - Card Selection Gallery
            Text("Gallery").font(Font.custom("Silka-Bold", size: 18))
            if viewModel.loadingCoverImages {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                Spacer()
            } else if (viewModel.frontCoverImages.isEmpty && viewModel.backCoverImages.isEmpty) &&
                        !viewModel.loadingCoverImages {
                VStack {
                    Spacer()
                    EmptyListView(message: "No stationary avaliable. Please visit the 'Content' section " +
                                    "of the Addressable.app portal to upload cover art and continue.")
                    Spacer()
                }
            } else {
                let images = isEditingBackCardCover ? viewModel.backCoverImages : viewModel.frontCoverImages
                let selectedCoverImageData = isEditingBackCardCover ?
                    $viewModel.selectedBackCoverImageData : $viewModel.selectedFrontCoverImageData
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(Array(images.keys).chunked(into: 2), id: \.self) { imageIdPair in
                            CoverImageGallery(
                                selectedCoverImageId: $viewModel.selectedCoverImageId,
                                selectedCoverImageData: selectedCoverImageData,
                                coverImages: images,
                                coverImageIdPair: imageIdPair
                            )
                        }
                    }
                }
            }
        }.onAppear {
            viewModel.getMailingCoverImageOptions()
        }
    }
}

struct CoverImageGallery: View {
    @Binding var selectedCoverImageId: Int
    @Binding var selectedCoverImageData: Data?

    var coverImages: [Int: MailingCoverImageData]
    var coverImageIdPair: [Int]

    init(
        selectedCoverImageId: Binding<Int>,
        selectedCoverImageData: Binding<Data?>,
        coverImages: [Int: MailingCoverImageData],
        coverImageIdPair: [Int]
    ) {
        self._selectedCoverImageId = selectedCoverImageId
        self._selectedCoverImageData = selectedCoverImageData

        self.coverImages = coverImages
        self.coverImageIdPair = coverImageIdPair
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(coverImageIdPair, id: \.self) { coverImageID in
                if let imageData = coverImages[coverImageID] {
                    Button(action: {
                        selectedCoverImageId = coverImageID
                        selectedCoverImageData = imageData.imageData
                    }) {
                        MailingCoverArtView(coverImage: imageData, labelFontSize: 12)
                    }
                }
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
    }
}
