//
//  UserAndPassword.swift
//  Addressable
//
//  Created by Arian Flores on 12/1/20.
//

import SwiftUI

struct UserAndPassword: View {
  @State var username: String = ""
  @State var password: String = ""
  @State var showingAlert = false
  @State var alertText: String = ""

  var body: some View {
    VStack {
      TextField("Username", text: $username)
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .textContentType(.username)
        .autocapitalization(.none)
        .disableAutocorrection(true)

      SecureField("Password", text: $password)
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .textContentType(.password)

      Button(action: signInTapped) {
        Text("Log In")
          .foregroundColor(Color.gray)
      }
      .alert(isPresented: $showingAlert) {
        Alert(title: Text(alertText))
      }
    }
    .padding()
  }

  private func signInTapped() {
    let ws = CharacterSet.whitespacesAndNewlines

    let account = username.trimmingCharacters(in: ws)
    let pwd = password.trimmingCharacters(in: ws)

    guard !(account.isEmpty || pwd.isEmpty) else {
      alertText = "Please enter a username and password."
      showingAlert = true
      return
    }

    /**
      * Putting the user/pwd into the shared web credentials ensures that
      * it's available for your browser based (Safari) logins if you haven't implemented
      * the web version of Sign in with Apple but also then makes it available
      * for future logins via Sign in with Apple on  iOS devices.
     
         SharedWebCredential(domain: "")
           .store(account: account, password: password) { result in
             guard case .failure = result else { return }
             self.alertText = "Failed to store password."
             self.showingAlert = true
         }
     */
  }
}

#if DEBUG
struct UserAndPassword_Previews: PreviewProvider {
  static var previews: some View {
    UserAndPassword()
  }
}
#endif
