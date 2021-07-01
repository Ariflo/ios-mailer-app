//
//  NavigationMenuView.swift
//  Addressable
//
//  Created by Ari on 5/24/21.
//

import SwiftUI

struct NavigationMenuView: View {
    @Binding var showNavMenu: Bool
    @Binding var selectedMenuItem: MainMenu

    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            ForEach(MainMenu.allCases, id: \.self) { menuItem in
                if menuItem != .mailingDetail {
                    Button(action: {
                        // Navigate to selected menu item
                        selectedMenuItem = menuItem
                        withAnimation {
                            showNavMenu = false
                        }
                    }) {
                        HStack {
                            Image(systemName: getIcon(for: menuItem))
                                .foregroundColor(Color.addressablePurple)
                                .imageScale(.large)
                            Text(menuItem.rawValue.capitalizingFirstLetter())
                                .font(Font.custom("Silka-Medium", size: 18))
                                .foregroundColor(Color.addressablePurple)
                                .font(.headline)
                        }
                        .padding(.top, 40)
                    }
                }
            }
            Spacer()
            if let versionNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String,
               let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                Text("Addressable v\(appVersion) (\(versionNumber))")
                    .font(Font.custom("Silka-Medium", size: 18))
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color.black)
                    .padding()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.addressableLightGray)
        .ignoresSafeArea(.all, edges: [.leading, .bottom, .trailing])
    }

    private func getIcon(for menuItem: MainMenu) -> String {
        switch menuItem {
        case .campaigns,
             .mailingDetail:
            return "mail"
        case .calls:
            return "phone"
        case .messages:
            return "message"
        case .profile:
            return "person"
        }
    }
}
#if DEBUG
struct NavigationMenuView_Previews: PreviewProvider {
    static var previews: some View {
        let selectedPreviewMenuItem = Binding<MainMenu>(
            get: { MainMenu.campaigns }, set: { _ in }
        )
        let showPreviewNavMenu = Binding<Bool>(
            get: { false }, set: { _ in }
        )
        NavigationMenuView(showNavMenu: showPreviewNavMenu, selectedMenuItem: selectedPreviewMenuItem)
    }
}
#endif
