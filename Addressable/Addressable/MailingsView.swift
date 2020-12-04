//
//  MailingsView.swift
//  Addressable
//
//  Created by Arian Flores on 12/3/20.
//

import SwiftUI

struct MailingsView: View {
    @State private var mailingItems: [MailingMailing] = []
    
    var body: some View {
        VStack {
            Text("Addressable Mailings").font(.title)
            Spacer()
            
            List(mailingItems) { mailing in
                Text(mailing.name)
            }
            Spacer()
        }.navigationBarHidden(true).onAppear { getMailings() }
    }
    
    func getMailings() {
        guard let url =  URL(string:"http://localhost:3000/api/v1/mailings") else {
            return
        }
        
        var request = URLRequest(url: url)
        
        request.setValue("application/json", forHTTPHeaderField: "ContentType")
        request.setValue("ari+123@addressable.app", forHTTPHeaderField: "X-User-Email")
        request.setValue("9BhZZxj87iZCriJtbUVgkz2n", forHTTPHeaderField: "X-User-Token")
        

        URLSession.shared.dataTask(with: request) { data, response, error in
            if error != nil {
                print("THIS IS THE ERROR ->", error!)
                return
            }
            // Verify data is not nil
            guard let data = data else {
                  print("NO DATA")
                  return
            }
            
            // Verify results as String
            guard let result = String(data: data, encoding: .utf8)  else {
                    return
            }
            print("THIS IS THE RESULT ->", result)
            
            // Add JSON Decoding in URLSession closure
            let decoder = JSONDecoder()
            guard let response = try? decoder.decode(MailingsResponse.self, from: data) else {
                print("NO RESPONSE DATA")
              return
            }
            
            print("THIS IS THE RESPONSE ->", response)
            // Update mailing items on main thread
            DispatchQueue.main.async {
                mailingItems = response.mailings.reduce(into: []) { mailings, mailingElement in
                    mailings.append(mailingElement.mailing)
                }
            }
          }.resume()
    }
}

struct MailingsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MailingsView()
        }
    }
}