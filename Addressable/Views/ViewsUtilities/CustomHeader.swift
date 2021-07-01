//
//  CustomHeader.swift
//  Addressable
//
//  Created by Ari on 5/24/21.
//

import SwiftUI

struct CustomHeader: View {
    let name: String
    let image: SwiftUI.Image
    let backgroundColor: Color

    var body: some View {
        HStack {
            image
                .imageScale(.large)
                .foregroundColor(Color.black)
            Text(name)
                .font(Font.custom("Silka-Medium", size: 16))
                .foregroundColor(Color.black)
            Spacer()
        }.background(backgroundColor)
    }
}
#if DEBUG
struct CustomHeader_Previews: PreviewProvider {
    static var previews: some View {
        CustomHeader(
            name: "Radius Mailings",
            image: Image(systemName: "mappin.and.ellipse"),
            backgroundColor: Color.addressablePurple
        )
    }
}
#endif
