//
//  SignInAddressable.swift
//  Addressable
//
//  Created by Arian Flores on 12/1/20.
//

import SwiftUI
import AuthenticationServices

final class SignInAddressableWithApple: UIViewRepresentable {
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        return ASAuthorizationAppleIDButton()
    }

    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {
    }
}
