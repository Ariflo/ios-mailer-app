//
//  TextFieldModifier.swift
//  Addressable
//
//  Created by Ari on 6/10/21.
//

import SwiftUI

struct TextFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Font.custom("Silka-Medium", size: 12))
            .padding(.leading, 12)
            .frame(minHeight: 44)
            .autocapitalization(.none)
            .disableAutocorrection(true)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.addressableLightestGray, lineWidth: 1)
            )
    }
}
