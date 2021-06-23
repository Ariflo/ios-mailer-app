//
//  CustomNote.swift
//  Addressable
//
//  Created by Ari on 5/20/21.
//

import SwiftUI

// MARK: - CustomNote
struct CustomNote: Codable {
    let id: Int

    enum CodingKeys: String, CodingKey {
        case id
    }
}

// MARK: - CustomNote.CoverImage
extension CustomNote {
    struct CoverImage: View {
        var image: UIImage

        init(imageData: Data) {
            // swiftlint:disable force_unwrapping
            self.image = UIImage(data: imageData) ?? UIImage(systemName: "exclamationmark.triangle")!
        }

        var body: some View {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        }
    }
}
