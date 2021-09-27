//
//  AppView.swift
//  Addressable
//
//  Created by Ari on 12/30/20.
//

import SwiftUI

enum AddressableView {
    case signIn
    case dashboard(Bool)
    case activeCall
    case composeRadius
}

struct AppView: View {
    @EnvironmentObject var app: Application

    init() {
        UITableView.appearance().backgroundColor = UIColor(
            red: 240 / 255,
            green: 240 / 255,
            blue: 240 / 255,
            alpha: 1.0
        )
        UITextField.appearance().clearButtonMode = .whileEditing
        UIPageControl.appearance().currentPageIndicatorTintColor = .black
        UIPageControl.appearance().pageIndicatorTintColor = UIColor(rgb: 0xDDDDDD)
    }

    var body: some View {
        NavigationView {
            switch app.currentView {
            case .signIn:
                SignInView(
                    viewModel: SignInViewModel(provider: app.dependencyProvider)
                )
                .navigationBarHidden(true)
                .environmentObject(app)
            case .dashboard(let shouldDisplayIncomingLeadSurvey):
                DashboardView(
                    viewModel: DashboardViewModel(provider: app.dependencyProvider),
                    displayIncomingLeadSurvey: shouldDisplayIncomingLeadSurvey
                )
                .environmentObject(app)
                .navigationBarHidden(true)
            case .activeCall:
                AddressableCallView(viewModel: CallsViewModel(provider: app.dependencyProvider))
                    .environmentObject(app)
                    .navigationBarHidden(true)
            case .composeRadius:
                ComposeRadiusView(
                    viewModel: ComposeRadiusViewModel(provider: app.dependencyProvider,
                                                      selectedMailing: app.selectedMailing)
                )
                .environmentObject(app)
                .navigationBarHidden(true)
            }
        }
    }
}

#if DEBUG
struct AppView_Previews: PreviewProvider {
    static var previews: some View {
        AppView().environmentObject(Application())
    }
}
#endif

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
