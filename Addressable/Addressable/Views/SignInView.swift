//
//  UserAndPassword.swift
//  Addressable
//
//  Created by Arian Flores on 12/1/20.
//

import SwiftUI

struct SignInView: View {
    @ObservedObject var viewModel: SignInViewModel

    init(viewModel: SignInViewModel) {
        self.viewModel = viewModel
    }

    @State var username: String = ""
    @State var password: String = ""
    @State var showingAlert = false
    @State var alertText: String = ""
    @State var authorizedUser: Int?
    @State var isNavigationBarHidden: Bool = true
    @State var secured: Bool = true

    var body: some View {
        VStack {
            Image("ZippyIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 250, height: 250)

            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.username)
                .autocapitalization(.none)
                .disableAutocorrection(true)

            HStack {
                if secured {
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.password)
                } else {
                    TextField("Password", text: $password)
                        .padding(4)
                        .border(Color.black, width: 1)
                }

                Button(action: {
                    secured.toggle()
                }) {
                    if secured {
                        EyeImage(name: "EyeClose")
                    } else {
                        EyeImage(name: "EyeOpen")
                    }
                }
            }

            NavigationLink(destination: AppView(), tag: 1, selection: $authorizedUser) {
                Button(action: {
                    let ws = CharacterSet.whitespacesAndNewlines

                    let account = username.trimmingCharacters(in: ws)
                    let pwd = password.trimmingCharacters(in: ws)

                    guard !(account.isEmpty || pwd.isEmpty) else {
                        alertText = "Please enter a username and password."
                        showingAlert = true
                        return
                    }

                    let loginString = String(format: "%@:%@", account, pwd)
                    let loginData = loginString.data(using: String.Encoding.utf8)!

                    viewModel.login(with: loginData.base64EncodedString()) { authenticatedUserInfo in
                        guard authenticatedUserInfo != nil else {
                            alertText = "Incorrect Username or Password. Try Agian!"
                            showingAlert = true
                            return
                        }
                        KeyChainServiceUtil.shared[USER_BASIC_AUTH_TOKEN] = loginData.base64EncodedString()
                        authorizedUser = 1
                    }
                }) {
                    Text("Log In")
                        .foregroundColor(Color.gray)
                }
                .alert(isPresented: $showingAlert) {
                    Alert(title: Text(alertText))
                }
            }
        }
        .padding()
    }
}

struct EyeImage: View {
    // 1
    private var imageName: String
    init(name: String) {
        self.imageName = name
    }

    // 2
    var body: some View {
        Image(imageName)
            .resizable()
            .foregroundColor(.black)
            .frame(width: 44, height: 44, alignment: .trailing)
    }
}

#if DEBUG
struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView(viewModel: SignInViewModel(addressableDataFetcher: AddressableDataFetcher()))
    }
}
#endif
