//
//  AddressableCallView.swift
//  Addressable
//
//  Created by Ari on 2/2/21.
//

import SwiftUI

struct AddressableCallView: View {
    @EnvironmentObject var app: Application
    @ObservedObject var viewModel: CallsViewModel

    @State var displayKeyPad = false
    @State var callOnHold = false
    @State var callIsMuted = false
    @State var callIsOnSpeaker = false

    init(viewModel: CallsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color(red: 78 / 255, green: 71 / 255, blue: 210 / 255)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 12) {
                VStack(spacing: 6) {
                    Text(app.callStatusText)
                        .font(.title)
                        .foregroundColor(.white)
                    Image("ZippyIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                }

                HStack(spacing: 25) {
                    // MARK: - Mute
                    VStack(spacing: 8) {
                        Button(action: {
                            guard let currentActiveCall = app.callManager?.currentActiveCall else {
                                print("No currentActiveCall avaliable to mute")
                                return
                            }
                            app.callManager?.setMuted(call: currentActiveCall, isMuted: !callIsMuted)
                            callIsMuted.toggle()
                        }) {
                            Image(systemName: callIsMuted ? "mic.slash.fill" : "mic.slash")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .padding()
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white, lineWidth: 4)
                                )
                        }
                        Text("Mute")
                            .font(.callout)
                            .foregroundColor(.white)
                    }
                    //                    // MARK: - Display KeyPad
                    //                    VStack(spacing: 8) {
                    //                        Button(action: {
                    //                            displayKeyPad = true
                    //                        }) {
                    //                            Image(systemName: "circle.grid.3x3")
                    //                                .resizable()
                    //                                .scaledToFit()
                    //                                .foregroundColor(.white)
                    //                                .frame(width: 50, height: 50)
                    //                                .padding()
                    //                                .overlay(
                    //                                    RoundedRectangle(cornerRadius: 16)
                    //                                        .stroke(Color.white, lineWidth: 4)
                    //                                )
                    //                        }
                    //                        Text("Keypad")
                    //                            .font(.callout)
                    //                            .foregroundColor(.white)
                    //                    }
                    // MARK: - Speaker
                    VStack(spacing: 8) {
                        Button(action: {
                            app.callManager?.toggleAudioToSpeaker(isSpeakerOn: !callIsOnSpeaker)
                            callIsOnSpeaker.toggle()
                        }) {
                            Image(systemName: callIsOnSpeaker ? "speaker.3.fill" : "speaker.3")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .padding()
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white, lineWidth: 4)
                                )
                        }
                        Text("Speaker")
                            .font(.callout)
                            .foregroundColor(.white)
                    }
                }

                HStack(spacing: 25) {
                    // MARK: - Hold
                    VStack(spacing: 8) {
                        Button(action: {
                            guard let currentActiveCall = app.callManager?.currentActiveCall else {
                                print("No currentActiveCall avaliable to hold")
                                return
                            }
                            app.callManager?.setHeld(call: currentActiveCall, onHold: !callOnHold)
                            callOnHold.toggle()
                        }) {
                            Image(systemName: callOnHold ? "pause.circle.fill": "pause.circle")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .padding()
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white, lineWidth: 4)
                                )
                        }
                        Text("Hold")
                            .font(.callout)
                            .foregroundColor(.white)
                    }
                    // MARK: - Add Participant
                    VStack(spacing: 8) {
                        Button(action: {
                            displayKeyPad = true
                        }) {
                            Image(systemName: app.callManager?.getIsCurrentCallIncoming() ?? false ? "person.crop.circle.badge.xmark":"person.badge.plus")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .padding()
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white, lineWidth: 4)
                                )
                        }.disabled(app.callManager?.getIsCurrentCallIncoming() ?? false)
                        Text("Add Caller")
                            .font(.callout)
                            .foregroundColor(.white)
                    }
                    // MARK: - Return to Campaigns
                    VStack(spacing: 8) {
                        Button(action: {
                            // Display Outgoing Call View
                            DispatchQueue.main.async {
                                app.displayCallView = false
                            }
                        }) {
                            Image(systemName: "mail")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .padding()
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white, lineWidth: 4)
                                )
                        }
                        Text("Campaigns")
                            .font(.callout)
                            .foregroundColor(.white)
                    }
                }

                Spacer()
                // MARK: - Hang Up Call
                Button( action: {
                    guard let currentActiveCall = app.callManager?.currentActiveCall else {
                        print("No currentActiveCall avaliable to end")
                        return
                    }

                    guard let index = app.callManager?.calls.firstIndex(where: { $0.incomingCall?.uuid == currentActiveCall.uuid || $0.outgoingCall?.uuid == currentActiveCall.uuid }) else { return }

                    guard let addressableCall = app.callManager?.calls[index] else {
                        print("No call in the logs to end")
                        return
                    }

                    app.callManager?.end(call: addressableCall)
                }) {
                    Image(systemName: "phone.down.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.red)
                        .frame(width: 50, height: 50)
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.red, lineWidth: 4)
                        )
                }
            }
        }.sheet(isPresented: $displayKeyPad) {
            KeyPadView(viewModel: CallsViewModel(addressableDataFetcher: AddressableDataFetcher())).navigationBarHidden(true)
        }
    }
}

struct AddressableCallView_Previews: PreviewProvider {
    static var previews: some View {
        AddressableCallView(viewModel: CallsViewModel(addressableDataFetcher: AddressableDataFetcher()))
    }
}
