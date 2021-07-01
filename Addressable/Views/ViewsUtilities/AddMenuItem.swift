//
//  AddMenuItem.swift
//  Addressable
//
//  Created by Ari on 5/26/21.
//

import SwiftUI

struct AddMenuItem: View {
    var icon: String
    var label: String
    var isComingSoon: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                Circle()
                    .foregroundColor(Color.addressablePurple)
                    .frame(width: 55, height: 55)
                Image(systemName: icon)
                    .imageScale(.large)
                    .foregroundColor(.white)
            }
            .shadow(color: .gray, radius: 0.2, x: 1, y: 1)
            .transition(.move(edge: .trailing))
            VStack(alignment: .leading) {
                Text(label)
                    .font(Font.custom("Silka-Medium", size: 18))
                    .foregroundColor(Color.addressablePurple)
                    .shadow(color: .gray, radius: 0.2, x: 1, y: 1)
                isComingSoon ? Text("Coming Soon")
                    .font(Font.custom("Silka-Medium", size: 16))
                    .foregroundColor(Color.addressableDarkGray)
                    .shadow(color: .gray, radius: 0.2, x: 1, y: 1) : nil
            }
        }
        .padding()
    }
}
#if DEBUG
struct AddMenuItem_Previews: PreviewProvider {
    static var previews: some View {
        AddMenuItem(icon: "mappin.and.ellipse", label: "Radius Mailer")
    }
}
#endif
