//
//  ContentView.swift
//  Addressable
//
//  Created by Arian Flores on 12/1/20.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        SignInView()
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
