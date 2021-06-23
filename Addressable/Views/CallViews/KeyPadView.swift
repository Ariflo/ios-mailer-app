//
//  KeyPadView.swift
//  Addressable
//
//  Created by Ari on 2/5/21.
//

import SwiftUI

struct KeyPadView: View {
    @EnvironmentObject var app: Application
    @ObservedObject var viewModel: CallsViewModel
    @State private var number = "0"

    init(viewModel: CallsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text(number)
            }.padding([.leading, .trailing])
            Divider()
            KeyPad(number: $number, viewModel: viewModel).environmentObject(app)
        }
        .font(.largeTitle)
        .padding()
    }
}

struct KeyPad: View {
    @EnvironmentObject var app: Application
    @Binding var number: String
    @ObservedObject var viewModel: CallsViewModel

    var body: some View {
        VStack {
            KeyPadRow(keys: ["1", "2", "3"])
            KeyPadRow(keys: ["4", "5", "6"])
            KeyPadRow(keys: ["7", "8", "9"])
            KeyPadRow(keys: [".", "0", "⌫"])
            KeyPadRow(keys: ["Add"])
        }.environment(\.keyPadButtonAction, self.keyWasPressed(_:))
    }

    private func keyWasPressed(_ key: String) {
        switch key {
        case "." where number.contains("."): break
        case "." where number == "0": number += key
        case "Add": addCallParticipant()
        case "⌫":
            number.removeLast()
            if number.isEmpty { number = "0" }
        case _ where number == "0": number = key
        default: number += key
        }
    }

    private func addCallParticipant() {
        guard let accountTwilioSmartNumber = app.callManager?.accountSmartNumberForCurrentCall else {
            print("No account smart number avaliable to add participant to call")
            return
        }
        viewModel.addCallParticipant(
            addNumber: number,
            fromNumber: accountTwilioSmartNumber
        )
    }
}

struct KeyPadButton: View {
    var key: String

    var body: some View {
        Button(action: { self.action(self.key) }) {
            Color.clear
                .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.accentColor))
                .overlay(Text(key))
        }
    }

    enum ActionKey: EnvironmentKey {
        static var defaultValue: (String) -> Void { { _ in } }
    }

    @Environment(\.keyPadButtonAction) var action: (String) -> Void
}

struct KeyPadRow: View {
    var keys: [String]

    var body: some View {
        HStack {
            ForEach(keys, id: \.self) { key in
                KeyPadButton(key: key)
            }
        }
    }
}

extension EnvironmentValues {
    var keyPadButtonAction: (String) -> Void {
        get { self[KeyPadButton.ActionKey.self] }
        set { self[KeyPadButton.ActionKey.self] = newValue }
    }
}

#if DEBUG
struct KeyPadView_Previews: PreviewProvider {
    static var previews: some View {
        KeyPadView(viewModel: CallsViewModel(provider: DependencyProvider()))
    }
}
#endif
