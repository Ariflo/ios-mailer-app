//
//  ComposeRadiusMailingCoverArtSelectionView.swift
//  Addressable
//
//  Created by Ari on 4/22/21.
//

import SwiftUI
import UIKit

struct ComposeRadiusMailingCoverArtSelectionView: View {
    @ObservedObject var viewModel: ComposeRadiusMailingViewModel
    @State var customizeCardCover: Bool = false

    init(viewModel: ComposeRadiusMailingViewModel) {
        self.viewModel = viewModel

        UIPageControl.appearance().currentPageIndicatorTintColor = .black
        UIPageControl.appearance().pageIndicatorTintColor = UIColor(rgb: 0xDDDDDD)
    }

    var body: some View {
        if viewModel.loadingImages {
            VStack {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                Spacer()
            }.frame(
                minWidth: 0,
                maxWidth: .infinity,
                minHeight: 0,
                maxHeight: .infinity,
                alignment: .center
            )
        } else if viewModel.mailingCoverImages.count < 1 && !viewModel.loadingImages {
            VStack {
                Spacer()
                EmptyListView(message: "No stationary avaliable. Please visit the 'Stationary & Content' section " +
                                "of the Addressable.app portal to upload cover art and continue.")
                Spacer()
            }
        } else {
            VStack {
                TabView(selection: $viewModel.selectedCoverImageID) {
                    ForEach(Array(viewModel.mailingCoverImages.keys), id: \.self) { coverImageID in
                        if let imageData = viewModel.mailingCoverImages[coverImageID] {
                            RadiusMailingCoverArt(viewModel: viewModel, coverImage: imageData)
                                .tag(coverImageID)
                        }
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 350)
                .tabViewStyle(PageTabViewStyle(
                                indexDisplayMode: customizeCardCover ? .always : .never)
                )
                .disabled(!customizeCardCover)

                Button(action: {
                    // Reveal Dots and Category Selector
                    customizeCardCover = !customizeCardCover

                    // Set Card Cover Selection
                    viewModel.selectedCoverImageID = customizeCardCover ? 0 : viewModel.selectedCoverImageID
                }) {
                    Text(!customizeCardCover ? "Customize" : "Select Card Cover")
                        .font(Font.custom("Silka-Medium", size: 14))
                        .foregroundColor(Color.black.opacity(0.3))
                        .underline()
                }
                Spacer()
            }
        }
    }
}

private struct RadiusMailingCoverArt: View {
    @ObservedObject var viewModel: ComposeRadiusMailingViewModel
    var coverImage: MailingCoverImageData

    init(viewModel: ComposeRadiusMailingViewModel, coverImage: MailingCoverImageData) {
        self.viewModel = viewModel
        self.coverImage = coverImage
    }

    var body: some View {
        VStack {
            CustomNote.CoverImage(imageData: coverImage.imageData)
            Text(coverImage.image.name?.replacingOccurrences(of: "_", with: " ") ?? "Untitled")
                .font(Font.custom("Silka-Regular", size: 18))
        }
    }
}

struct ComposeRadiusMailingCoverArtSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ComposeRadiusMailingCoverArtSelectionView(viewModel: ComposeRadiusMailingViewModel(selectedRadiusMailing: nil))
    }
}
