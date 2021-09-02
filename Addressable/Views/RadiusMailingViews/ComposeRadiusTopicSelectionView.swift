//
//  ComposeRadiusTopicSelectionView.swift
//  Addressable
//
//  Created by Ari on 4/22/21.
//

import Foundation
import SwiftUI

enum AddressableTouch: String, CaseIterable {
    case touchOne = "Touch 1"
    case touchTwo = "Touch 2"
}

// swiftlint:disable file_length
struct ComposeRadiusTopicSelectionView: View {
    @ObservedObject var viewModel: ComposeRadiusViewModel
    @StateObject var touchOnePreviewViewModel = PreviewViewModel()
    @StateObject var touchTwoPreviewViewModel = PreviewViewModel()

    @State var isTouchOnePreviewLoading: Bool = true
    @State var isTouchTwoPreviewLoading: Bool = true

    @State var isEditingTouchOne: Bool = false
    @State var isEditingTouchTwo: Bool = false

    var showAlert: () -> Void

    init(viewModel: ComposeRadiusViewModel, showAlert: @escaping () -> Void = { }) {
        self.viewModel = viewModel
        self.showAlert = showAlert
    }

    var body: some View {
        VStack {
            if viewModel.loadingTopics {
                VStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Spacer()
                }.frame(
                    minWidth: 0,
                    maxWidth: .infinity,
                    minHeight: 0,
                    maxHeight: .infinity,
                    alignment: .center
                )
            } else if viewModel.topics.count < 1 && !viewModel.loadingTopics {
                Spacer()
                EmptyListView(message: "No topics avaliable. " +
                                "Please reach out to your Addressable administrator or " +
                                "representative to create topics to select here and continue."
                )
                Spacer()
            } else if !viewModel.loadingTopics {
                ScrollView(.vertical, showsIndicators: false) {
                    Text("Select your campaign and complete the merge tags below each touch.")
                        .font(Font.custom("Silka-Medium", size: 14))
                        .foregroundColor(Color.black.opacity(0.3))
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 8)
                    Text("Merge tags pull in data for your cards from the information you provide here," +
                            " from your uploaded audience list, as well as your user profile.")
                        .font(Font.custom("Silka-Medium", size: 14))
                        .foregroundColor(Color.black.opacity(0.3))
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 8)
                    // MARK: - Choose Radius Topic
                    Menu {
                        ForEach(viewModel.topics) { topic in
                            Button {
                                setSelectedTopic(selectedTopic: topic)
                            } label: {
                                Text(topic.name).font(Font.custom("Silka-Medium", size: 14))
                            }
                        }
                    } label: {
                        HStack(alignment: .center) {
                            Text(getSelectedTopicName())
                                .font(Font.custom("Silka-Medium", size: 14))
                                .padding()
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.black)
                                .opacity(0.5)
                                .padding()
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.addressableLightestGray, lineWidth: 1)
                            .animation(.easeOut)
                    )
                    .background(Color.white)
                    .frame(minWidth: 295, minHeight: 54)
                    .foregroundColor(.black)
                    // MARK: - Touch 1 + Merge Vars
                    VStack(alignment: .center, spacing: 25) {
                        Text(AddressableTouch.touchOne.rawValue).font(Font.custom("Silka-Medium", size: 16))
                        if isEditingTouchOne {
                            TextEditorView(
                                viewModel: viewModel,
                                touchViewModel: touchOnePreviewViewModel,
                                touch: .touchOne,
                                showAlert: showAlert,
                                setIsEditingOff: {
                                    isEditingTouchOne = false
                                }
                            )
                        } else {
                            CustomNotePreviewView(
                                viewModel: viewModel,
                                touchViewModel: touchOnePreviewViewModel,
                                touch: .touchOne,
                                isLoading: isTouchOnePreviewLoading,
                                setIsLoading: { value in isTouchOnePreviewLoading = value },
                                setIsEditingOn: {
                                    isEditingTouchOne = true
                                }
                            )
                            if !isTouchOnePreviewLoading {
                                ForEach(
                                    getSortedMergeTags(for: .touchOne).compactMap { $0 },
                                    id: \.self
                                ) { mergeTagName in
                                    MergeVariableInput(
                                        viewModel: viewModel,
                                        touch: .touchOne,
                                        mergeTagName: mergeTagName
                                    )
                                }
                            }
                        }
                    }.padding(.top, 40)

                    DottedLine()
                        .stroke(style: StrokeStyle(lineWidth: 3, dash: [4]))
                        .frame(width: 1, height: 75)
                        .foregroundColor(Color(red: 0, green: 0, blue: 0, opacity: 0.3))
                        .padding()

                    // MARK: - Touch 2 + Merge Vars
                    VStack(alignment: .center, spacing: 25) {
                        Text(AddressableTouch.touchTwo.rawValue).font(Font.custom("Silka-Medium", size: 16))
                        if isEditingTouchTwo {
                            TextEditorView(
                                viewModel: viewModel,
                                touchViewModel: touchTwoPreviewViewModel,
                                touch: .touchTwo,
                                showAlert: showAlert,
                                setIsEditingOff: {
                                    isEditingTouchTwo = false
                                }
                            )
                        } else {
                            CustomNotePreviewView(
                                viewModel: viewModel,
                                touchViewModel: touchTwoPreviewViewModel,
                                touch: .touchTwo,
                                isLoading: isTouchTwoPreviewLoading,
                                setIsLoading: { value in isTouchTwoPreviewLoading = value },
                                setIsEditingOn: {
                                    isEditingTouchTwo = true
                                }
                            )
                            if !isTouchTwoPreviewLoading {
                                ForEach(
                                    getSortedMergeTags(for: .touchTwo).compactMap { $0 },
                                    id: \.self
                                ) { mergeTagName in
                                    MergeVariableInput(
                                        viewModel: viewModel,
                                        touch: .touchTwo,
                                        mergeTagName: mergeTagName
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 40)
        .onAppear {
            viewModel.getRadiusMailingMultiTouchTopics()
        }
    }
    private func getSortedMergeTags(for touch: AddressableTouch) -> [String?] {
        let mergeVars = touch == .touchOne ?
            viewModel.touchOneTemplateMergeVariables :
            viewModel.touchTwoTemplateMergeVariables
        if let templateBody = touch == .touchOne ? viewModel.touchOneTemplate?.body : viewModel.touchTwoTemplate?.body {
            return mergeVars.keys.reduce(
                into: Array(repeating: nil, count: templateBody.count)
            ) { sortedMergeTags, mergeTag in
                if let range = templateBody.range(of: mergeTag, options: .caseInsensitive) {
                    let index: Int = templateBody.distance(from: templateBody.startIndex, to: range.lowerBound)
                    sortedMergeTags.insert(mergeTag, at: index)
                }
            }
        }
        return []
    }
    private func setSelectedTopic(selectedTopic: MultiTouchTopic) {
        viewModel.topicSelectionID = selectedTopic.id
        if let selectedMultiTouchTopic = viewModel.topics.first(where: { topic in topic.id == selectedTopic.id }) {
            viewModel.getMessageTemplates(for: selectedMultiTouchTopic)
            // Refresh WebViews on every topic selection
            touchOnePreviewViewModel.reloadWebView = true
            touchTwoPreviewViewModel.reloadWebView = true
        }
    }
    private func getSelectedTopicName() -> String {
        if let selectedMultiTouchTopic = viewModel.topics.first(where: { topic in topic.id == viewModel.topicSelectionID }) {
            return selectedMultiTouchTopic.name
        }
        return "No Topic Selected"
    }
}

// MARK: - MergeVariableInput
struct MergeVariableInput: View {
    @ObservedObject var viewModel: ComposeRadiusViewModel
    var touch: AddressableTouch = .touchOne
    var mergeTagName: String = ""

    init(
        viewModel: ComposeRadiusViewModel,
        touch: AddressableTouch = .touchOne,
        mergeTagName: String = ""
    ) {
        self.viewModel = viewModel
        self.touch = touch
        self.mergeTagName = mergeTagName
    }

    var body: some View {
        let mergeVarsBinding = Binding<String>(
            get: {
                if touch == .touchOne {
                    return viewModel.touchOneTemplateMergeVariables[mergeTagName] ?? ""
                } else {
                    return viewModel.touchTwoTemplateMergeVariables[mergeTagName] ?? ""
                }
            },
            set: { mergeTagValue in
                if touch == .touchOne {
                    viewModel.touchOneTemplateMergeVariables[mergeTagName] = mergeTagValue
                } else {
                    viewModel.touchTwoTemplateMergeVariables[mergeTagName] = mergeTagValue
                }
            })

        VStack(alignment: .leading, spacing: 4) {
            Text(mergeTagName).font(Font.custom("Silka-Light", size: 12))
            TextField("", text: mergeVarsBinding)
                .modifier(TextFieldModifier())
        }
    }
}

// MARK: - TextEditorView
struct TextEditorView: View {
    @ObservedObject var viewModel: ComposeRadiusViewModel
    @ObservedObject var touchViewModel: PreviewViewModel

    var touch: AddressableTouch
    var showAlert: () -> Void
    var setIsEditingOff: () -> Void

    init(
        viewModel: ComposeRadiusViewModel,
        touchViewModel: PreviewViewModel,
        touch: AddressableTouch = .touchOne,
        showAlert: @escaping () -> Void,
        setIsEditingOff: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.touchViewModel = touchViewModel
        self.touch = touch
        self.showAlert = showAlert
        self.setIsEditingOff = setIsEditingOff
    }

    var body: some View {
        ZStack {
            TextEditor(text: touch == .touchOne ? $viewModel.touchOneBody : $viewModel.touchTwoBody)
                .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.1), radius: 3, x: 2, y: 2)
                .frame(minWidth: 300, minHeight: 450)
            VStack {
                Button(action: {
                    if let templateID = touch == .touchOne ?
                        viewModel.touchOneTemplate?.id :
                        viewModel.touchTwoTemplate?.id {
                        viewModel.updateMessageTemplate(
                            for: touch,
                            templateId: templateID,
                            with: touch == .touchOne ?
                                viewModel.touchOneBody :
                                viewModel.touchTwoBody
                        ) { updatedTemplate in
                            if let updatedTemplate = updatedTemplate {
                                viewModel.getTopicsMessageTemplate(
                                    for: touch == .touchOne ? 1 : 2,
                                    with: updatedTemplate.id) { template in
                                    guard template != nil else {
                                        showAlert()
                                        return
                                    }
                                    touchViewModel.reloadWebView = true
                                    setIsEditingOff()
                                }
                            } else {
                                showAlert()
                                return
                            }
                        }
                    }
                }) {
                    Text("Show Preview")
                        .font(Font.custom("Silka-Medium", size: 14))
                        .foregroundColor(Color.black.opacity(0.3))
                        .underline()
                }.padding(25)
            }.frame(
                minWidth: 0,
                maxWidth: .infinity,
                minHeight: 0,
                maxHeight: .infinity,
                alignment: .bottomTrailing
            )
        }
    }
}

// MARK: - CustomNotePreviewView
struct CustomNotePreviewView: View {
    @ObservedObject var viewModel: ComposeRadiusViewModel
    var touchViewModel: PreviewViewModel

    var touch: AddressableTouch
    var isLoading: Bool
    var setIsLoading: (Bool) -> Void
    var setIsEditingOn: () -> Void

    init(
        viewModel: ComposeRadiusViewModel,
        touchViewModel: PreviewViewModel,
        touch: AddressableTouch = .touchOne,
        isLoading: Bool = false,
        setIsLoading: @escaping (Bool) -> Void,
        setIsEditingOn: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.touchViewModel = touchViewModel
        self.touch = touch
        self.isLoading = isLoading
        self.setIsLoading = setIsLoading
        self.setIsEditingOn = setIsEditingOn
    }

    var body: some View {
        ZStack {
            if let mailing = viewModel.touchOneMailing,
               let templateId = touch == .touchOne ?
                viewModel.touchOneTemplate?.id : viewModel.touchTwoTemplate?.id {
                PreviewView(viewModel: touchViewModel,
                            mailing: mailing,
                            messageTemplateId: templateId)
                    .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.1), radius: 3, x: 2, y: 2)
                    .frame(minWidth: 300, minHeight: 450)
                VStack {
                    Button(action: {
                        setIsEditingOn()
                    }) {
                        Text("Edit")
                            .font(Font.custom("Silka-Medium", size: 14))
                            .foregroundColor(Color.black.opacity(0.3))
                            .underline()
                    }.padding(25)
                }.frame(
                    minWidth: 0,
                    maxWidth: .infinity,
                    minHeight: 0,
                    maxHeight: .infinity,
                    alignment: .bottomTrailing
                )
            }
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .frame(minWidth: 300, minHeight: 450)
            }
        }.onReceive(touchViewModel.showLoader.receive(on: RunLoop.main)) { value in
            // Give zipscribe.js time to render handwritten preview
            if isLoading && !value {
                DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
                    setIsLoading(value)
                }
            } else {
                setIsLoading(value)
            }
        }
    }
}

struct DottedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        return path
    }
}
#if DEBUG
struct ComposeRadiusTopicSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ComposeRadiusTopicSelectionView(
            viewModel: ComposeRadiusViewModel(
                provider: DependencyProvider(),
                selectedMailing: nil)
        )
    }
}
#endif
