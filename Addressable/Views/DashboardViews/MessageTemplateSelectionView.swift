//
//  MessageTemplateSelectionView.swift
//  Addressable
//
//  Created by Ari on 8/6/21.
//

import SwiftUI

struct MessageTemplateSelectionView: View, Equatable {
    static func == (lhs: MessageTemplateSelectionView, rhs: MessageTemplateSelectionView) -> Bool {
        lhs.viewModel.mailing == rhs.viewModel.mailing
    }

    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: MessageTemplateSelectionViewModel
    @StateObject var messageTemplatePreviewViewModel = PreviewViewModel()

    @State var isMessagePreviewLoading: Bool = true
    @State var isEditingMessageTemplate: Bool = false
    @State var showingAlert: Bool = false

    init(
        viewModel: MessageTemplateSelectionViewModel
    ) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.loadingMessageTemplates {
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
                } else if viewModel.messageTemplates.count < 1 && !viewModel.loadingMessageTemplates {
                    Spacer()
                    EmptyListView(message: "No message templates avaliable. " +
                                    "Please reach out to an Addressable administrator or " +
                                    "representative to create message templates to select here and continue."
                    )
                    Spacer()
                } else if !viewModel.loadingMessageTemplates {
                    ScrollView(.vertical, showsIndicators: false) {
                        // MARK: - Choose Message Template
                        Menu {
                            ForEach(viewModel.messageTemplates) { messageTemplate in
                                Button {
                                    setSelectedMessageTemplate(selectedMessageTemplate: messageTemplate)
                                } label: {
                                    Text(messageTemplate.title).font(Font.custom("Silka-Medium", size: 14))
                                }
                            }
                        } label: {
                            HStack(alignment: .center) {
                                Text(getSelectedMessageTemplateTitle())
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
                        // MARK: - Message Template Preview + Merge Vars
                        if viewModel.selectedMessageTemplateID == 0 {
                            EmptyListView(message: "Please select a message template to preview.")
                        } else {
                            VStack {
                                if isEditingMessageTemplate {
                                    if let selectedMessageTemplate = getSelectedMessageTemplate() {
                                        MessageTemplateTextEditorView(
                                            viewModel: viewModel,
                                            messageTemplatePreviewViewModel: messageTemplatePreviewViewModel,
                                            messageTemplate: selectedMessageTemplate,
                                            showAlert: {
                                                showingAlert = true
                                            },
                                            setIsEditingOff: {
                                                isEditingMessageTemplate = false
                                            }
                                        )
                                    }
                                } else {
                                    MessageTemplatePreviewView(
                                        viewModel: viewModel,
                                        previewViewModel: messageTemplatePreviewViewModel,
                                        isLoading: isMessagePreviewLoading,
                                        setIsLoading: { value in isMessagePreviewLoading = value },
                                        setIsEditingOn: {
                                            isEditingMessageTemplate = true
                                        }
                                    )
                                    if !isMessagePreviewLoading {
                                        ForEach(
                                            getSelectedMessageTemplateMergeVars(),
                                            id: \.self
                                        ) { mergeTagName in
                                            MessageTemplateMergeVariableInput(
                                                viewModel: viewModel,
                                                mergeTagName: mergeTagName
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                Spacer()
                HStack(spacing: 8) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Cancel")
                            .font(Font.custom("Silka-Medium", size: 18))
                            .padding()
                            .foregroundColor(Color.addressableDarkGray)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.addressableDarkGray, lineWidth: 1)
                            )
                            .multilineTextAlignment(.center)
                    }
                    Button(action: {
                        if let selectedMessageTemplate = getSelectedMessageTemplate() {
                            viewModel.addMessageTemplate(with: selectedMessageTemplate.id) { mailingWithMessageTemplate in
                                if let newMailing = mailingWithMessageTemplate {
                                    viewModel.mailing = newMailing
                                    presentationMode.wrappedValue.dismiss()
                                } else {
                                    showingAlert = true
                                }
                            }
                        }
                    }) {
                        Text("Add Message Template")
                            .font(Font.custom("Silka-Medium", size: 18))
                            .padding()
                            .foregroundColor(Color.white)
                            .background(Color.addressablePurple)
                            .cornerRadius(5)
                            .multilineTextAlignment(.center)
                    }
                    .disabled(isMissingMergeVars() || viewModel.selectedMessageTemplateID == 0)
                    .opacity(isMissingMergeVars() || viewModel.selectedMessageTemplateID == 0 ? 0.4 : 1)
                }
            }
            .navigationBarTitle("Message Template", displayMode: .inline)
            .onAppear {
                viewModel.getMessageTemplates()
            }
            .padding()
            .background(Color.addressableLightGray)
        }.alert(isPresented: $showingAlert) {
            Alert(title: Text("Sorry something went wrong," +
                                " try again or reach out to an Addressable " +
                                " representative if the problem persists.")
            )
        }
    }
    private func isMissingMergeVars() -> Bool {
        guard !getSelectedMessageTemplateMergeVars().isEmpty else { return false }

        if getSelectedMessageTemplateMergeVars().count == viewModel.messageTemplateMergeVariables.keys.count {
            return !getSelectedMessageTemplateMergeVars().filter {
                viewModel.messageTemplateMergeVariables[$0]?.isEmpty ?? true
            }.isEmpty
        }
        return true
    }
    private func setSelectedMessageTemplate(selectedMessageTemplate: MessageTemplate) {
        viewModel.selectedMessageTemplateID = selectedMessageTemplate.id
    }
    private func getSelectedMessageTemplateTitle() -> String {
        if let selectedMessageTemplate = viewModel.messageTemplates.first(
            where: { messageTemplate in messageTemplate.id == viewModel.selectedMessageTemplateID }
        ) {
            return selectedMessageTemplate.title
        }
        return "Select Message Template"
    }
    private func getSelectedMessageTemplateMergeVars() -> [String] {
        if let selectedMessageTemplate = viewModel.messageTemplates.first(
            where: { messageTemplate in messageTemplate.id == viewModel.selectedMessageTemplateID }
        ) {
            return selectedMessageTemplate.mergeVars
        }
        return []
    }
    private func getSelectedMessageTemplate() -> MessageTemplate? {
        return viewModel.messageTemplates.first { messageTemplate in
            messageTemplate.id == viewModel.selectedMessageTemplateID
        }
    }
}

// MARK: - MessageTemplatePreviewView
struct MessageTemplatePreviewView: View {
    @ObservedObject var viewModel: MessageTemplateSelectionViewModel

    var previewViewModel: PreviewViewModel

    var isLoading: Bool
    var setIsLoading: (Bool) -> Void
    var setIsEditingOn: () -> Void


    init(
        viewModel: MessageTemplateSelectionViewModel,
        previewViewModel: PreviewViewModel,
        isLoading: Bool = false,
        setIsLoading: @escaping (Bool) -> Void,
        setIsEditingOn: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.previewViewModel = previewViewModel
        self.isLoading = isLoading
        self.setIsLoading = setIsLoading
        self.setIsEditingOn = setIsEditingOn
    }

    var body: some View {
        ZStack {
            if let templateID = getSelectedMessageTemplateId() {
                PreviewView(viewModel: previewViewModel,
                            mailing: viewModel.mailing,
                            messageTemplateId: templateID
                )
                .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.1), radius: 3, x: 2, y: 2)
                .frame(maxWidth: 300, minHeight: 350)
                VStack {
                    Button(action: {
                        setIsEditingOn()
                    }) {
                        Text("Edit")
                            .font(Font.custom("Silka-Medium", size: 14))
                            .foregroundColor(Color.black.opacity(0.3))
                            .underline()
                    }
                    .padding(.trailing, 60)
                    .padding(.vertical, 25)
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
                    .frame(maxWidth: 300, minHeight: 350)
            }
        }.onReceive(previewViewModel.showLoader.receive(on: RunLoop.main)) { value in
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
    private func getSelectedMessageTemplateId() -> Int? {
        if let selectedMessageTemplate = viewModel.messageTemplates.first(
            where: { messageTemplate in messageTemplate.id == viewModel.selectedMessageTemplateID }
        ) {
            return selectedMessageTemplate.id
        }
        return nil
    }
}

// MARK: - MessageTemplateMergeVariableInput
struct MessageTemplateMergeVariableInput: View {
    @ObservedObject var viewModel: MessageTemplateSelectionViewModel
    var mergeTagName: String = ""

    init(
        viewModel: MessageTemplateSelectionViewModel,
        mergeTagName: String = ""
    ) {
        self.viewModel = viewModel
        self.mergeTagName = mergeTagName
    }

    var body: some View {
        let mergeVarsBinding = Binding<String>(
            get: { viewModel.messageTemplateMergeVariables[mergeTagName] ?? "" },
            set: { mergeTagValue in
                viewModel.messageTemplateMergeVariables[mergeTagName] = mergeTagValue
            })
        VStack(alignment: .leading, spacing: 4) {
            Text(mergeTagName).font(Font.custom("Silka-Light", size: 12))
            TextField("", text: mergeVarsBinding)
                .modifier(TextFieldModifier())
        }
    }
}
// MARK: - MessageTemplateTextEditorView
struct MessageTemplateTextEditorView: View {
    @ObservedObject var viewModel: MessageTemplateSelectionViewModel
    @ObservedObject var messageTemplatePreviewViewModel: PreviewViewModel

    var messageTemplate: MessageTemplate
    var showAlert: () -> Void
    var setIsEditingOff: () -> Void

    init(
        viewModel: MessageTemplateSelectionViewModel,
        messageTemplatePreviewViewModel: PreviewViewModel,
        messageTemplate: MessageTemplate,
        showAlert: @escaping () -> Void,
        setIsEditingOff: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.messageTemplatePreviewViewModel = messageTemplatePreviewViewModel
        self.messageTemplate = messageTemplate
        self.showAlert = showAlert
        self.setIsEditingOff = setIsEditingOff
    }

    var body: some View {
        ZStack {
            TextEditor(text: $viewModel.messageTemplateBody)
                .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.1), radius: 3, x: 2, y: 2)
                .frame(maxWidth: 300, minHeight: 350)
            VStack {
                Button(action: {
                    viewModel.updateMessageTemplate(with: messageTemplate.id) { updatedTemplate in
                        guard updatedTemplate != nil else {
                            showAlert()
                            return
                        }
                        messageTemplatePreviewViewModel.reloadWebView = true
                        setIsEditingOff()
                    }
                }) {
                    Text("Show Preview")
                        .font(Font.custom("Silka-Medium", size: 14))
                        .foregroundColor(Color.black.opacity(0.3))
                        .underline()
                }
                .padding(.trailing, 60)
                .padding(.vertical, 25)
            }.frame(
                minWidth: 0,
                maxWidth: .infinity,
                minHeight: 0,
                maxHeight: .infinity,
                alignment: .bottomTrailing
            )
        }.onAppear {
            viewModel.messageTemplateBody = messageTemplate.body
        }
    }
}
