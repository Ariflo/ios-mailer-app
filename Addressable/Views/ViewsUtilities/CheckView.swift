//
//  CheckView.swift
//  Addressable
//
//  Created by Ari on 4/26/21.
//

import SwiftUI

struct CheckView: View {
    var isChecked: Bool = false
    var title: String
    var subTitles: [String]?

    var toggle: () -> Void

    var body: some View {
        HStack(alignment: subTitles == nil ? .center : .top) {
            Button(action: toggle) {
                Image(systemName: isChecked ? "checkmark.circle": "circle")
            }
            subTitles == nil ?
                Text(title)
                .minimumScaleFactor(0.1)
                .font(Font.custom("Silka-Medium", size: 12)) : nil
            if let labels = subTitles {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .minimumScaleFactor(0.1)
                        .font(Font.custom("Silka-Medium", size: 12))
                    ForEach(labels, id: \.self) { label in
                        Text(label)
                            .minimumScaleFactor(0.1)
                            .font(Font.custom("Silka-Medium", size: 12))
                            .foregroundColor(Color.addressableFadedBlack)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
        }.foregroundColor(Color.addressablePurple)
    }
}
#if DEBUG
struct CheckView_Previews: PreviewProvider {
    static var previews: some View {
        CheckView(title: "Title") {}
    }
}
#endif
