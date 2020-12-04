//
//  UserAndPassword.swift
//  Addressable
//
//  Created by Arian Flores on 12/1/20.
//

import SwiftUI

struct UserAndPassword: View {
  @State var username: String = "" // TODO: Case Sensative
  @State var password: String = ""
  @State var showingAlert = false
  @State var alertText: String = ""
  @State var successfullyLoggedin: Int? = nil
  @State var isNavigationBarHidden: Bool = true

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
        
      NavigationLink(destination: MailingsView(), tag: 1, selection: $successfullyLoggedin) {
        Button(action: signInTapped) {
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

  private func signInTapped() {
    let ws = CharacterSet.whitespacesAndNewlines

    let account = username.trimmingCharacters(in: ws)
    let pwd = password.trimmingCharacters(in: ws)

    guard !(account.isEmpty || pwd.isEmpty) else {
      alertText = "Please enter a username and password."
      showingAlert = true
      return
    }
    
    signUserIn(userEmail: account, unHashedpwd: pwd)
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
  private func signUserIn(userEmail: String, unHashedpwd: String) {
    guard let url =  URL(string:"http://localhost:3000/api/v1/auth.json") else {
        return
    }
    var request = URLRequest(url: url)
    
    request.setValue("application/json", forHTTPHeaderField: "ContentType")
    request.setValue(userEmail, forHTTPHeaderField: "X-User-Email")
    request.setValue("9BhZZxj87iZCriJtbUVgkz2n", forHTTPHeaderField: "X-User-Token")
    

    URLSession.shared.dataTask(with: request) { data, response, error in
        if error != nil {
            print("THIS IS THE ERROR ->", error!)
            return
        }
          // Verify data is not nil
          guard let data = data else {
                  return
              }
          // Verify response is Success
          guard let httpResponse = response as? HTTPURLResponse,
                (200..<300).contains(httpResponse.statusCode) else {
              return
          }
        
        // Verify result can be converted to String
        guard let result = String(data: data, encoding: .utf8)  else {
                return
        }
        print("THIS IS THE RESULT ->", result)
        successfullyLoggedin = 1
      }.resume()
  }
//    *** Consider using this with Sign-up ***
//    private func getAuthToken() -> String {
//        let loginString = String(format: "%@:%@", username, password)
//
//        print("THIS IS THE LOGIN STRING ->", loginString)
//
//        let loginData = loginString.data(using: String.Encoding.utf8)!
//
//        print("THIS IS THE TOKEN ->", loginData.base64EncodedString())
//
//        return "Basic \(loginData.base64EncodedString())"
//    }
}

#if DEBUG
struct UserAndPassword_Previews: PreviewProvider {
  static var previews: some View {
    UserAndPassword()
  }
}
#endif
