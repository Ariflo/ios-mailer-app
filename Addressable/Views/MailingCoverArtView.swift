//
//  MailingCoverArtView.swift
//  Addressable
//
//  Created by Ari on 6/16/21.
//

import SwiftUI

struct MailingCoverArtView: View {
    var coverImage: MailingCoverImageData
    var labelFontSize: CGFloat = 18

    init(coverImage: MailingCoverImageData, labelFontSize: CGFloat = 18) {
        self.coverImage = coverImage
        self.labelFontSize = labelFontSize
    }

    var body: some View {
        VStack {
            CustomNote.CoverImage(imageData: coverImage.imageData)
            Text(coverImage.image.name?.replacingOccurrences(of: "_", with: " ") ?? "Untitled")
                .font(Font.custom("Silka-Medium", size: labelFontSize))
                .padding(.bottom, 6)
                .foregroundColor(Color.black)
        }
    }
}
