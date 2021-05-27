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

    var toggle: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            Button(action: toggle) {
                Image(systemName: isChecked ? "checkmark.circle": "circle")
            }
            Text(title).minimumScaleFactor(0.1).font(Font.custom("Silka-Medium", size: 12))
        }.foregroundColor(Color.addressablePurple)
    }
}

struct CheckView_Previews: PreviewProvider {
    static var previews: some View {
        CheckView(title: "Title", toggle: {})
    }
}
