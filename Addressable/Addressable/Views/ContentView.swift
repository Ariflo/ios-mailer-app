//
//  ContentView.swift
//  Addressable
//
//  Created by Arian Flores on 12/1/20.
//

import UIKit
import SwiftUI
import AuthenticationServices

struct ContentView: View {
    @State var appleSignInDelegates: SignInWithAppleDelegates! = nil

    var body: some View {
        VStack {
            Image("AddressableAssests")

            UserAndPassword()
                .padding()

            SignInAddressableWithApple()
                .frame(width: 280, height: 60)
                .onTapGesture(perform: showAppleLogin)
        }.onAppear {
            self.performExistingAccountSetupFlows()
        }
    }

    private func showAppleLogin() {
        let request = ASAuthorizationAppleIDProvider().createRequest()

        request.requestedScopes = [.fullName, .email]
        performSignIn(using: [request])
    }

    private func performSignIn(using requests: [ASAuthorizationRequest]) {
        appleSignInDelegates = SignInWithAppleDelegates { success in
            if success {
                // update UI
            } else {
                // show the user an error
            }
        }

        let controller = ASAuthorizationController(authorizationRequests: requests)
        controller.delegate = appleSignInDelegates

        controller.performRequests()
    }

    private func performExistingAccountSetupFlows() {
        #if !targetEnvironment(simulator)

        let requests = [
            ASAuthorizationAppleIDProvider().createRequest(),
            ASAuthorizationPasswordProvider().createRequest()
        ]

        performSignIn(using: requests)
        #endif
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
        }
    }
}
#endif
