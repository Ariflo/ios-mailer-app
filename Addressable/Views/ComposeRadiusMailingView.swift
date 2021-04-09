//
//  ComposeRadiusMailingView.swift
//  Addressable
//
//  Created by Ari on 2/11/21.
//

import SwiftUI
import GoogleMaps

// MARK: - ListEntryStatus
enum ListEntryStatus: String {
    case active, rejected
}
// MARK: - ComposeRadiusMailingSteps
enum ComposeRadiusMailingSteps: String, CaseIterable {
    case selectLocation = "Location of Sale"
    case selectCard = "Select Card"
    case chooseTopic = "Choose Campaign Type"
    case confirmAndProcess = "Confirm & Process"
    case audienceProcessing = "Audience Processing"
    case confirmAudience = "Confirm Audience"
    case confirmSend = "Confirm and Send"
    case radiusSent = "Radius Mailing Sent"
}
// MARK: - ComposeRadiusMailingAlerts
enum ComposeRadiusMailingAlerts {
    case requiredAddressFieldsEmpty, requiredMergeFieldsFieldsEmpty
}

// MARK: - ComposeRadiusMailingView
struct ComposeRadiusMailingView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @ObservedObject var viewModel: ComposeRadiusMailingViewModel
    @State var showingAlert: Bool = false
    @State private var alertType: ComposeRadiusMailingAlerts = .requiredAddressFieldsEmpty

    init(viewModel: ComposeRadiusMailingViewModel) {
        self.viewModel = viewModel

        if self.viewModel.selectedRadiusMailing?.status == "list_added" {
            self.viewModel.step = .confirmAudience
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                switch viewModel.step {
                case .selectLocation:
                    ComposeRadiusMailingSelectLocationView(viewModel: viewModel)
                case .selectCard:
                    ComposeRadiusMailingCoverArtSelectionView(viewModel: viewModel)
                case .chooseTopic:
                    ComposeRadiusMailingTopicSelectionView(viewModel: viewModel)
                case .confirmAndProcess:
                    ComposeRadiusMailingConfirmationView(viewModel: viewModel)
                case .audienceProcessing:
                    ComposeRadiusMailingListConfirmationView()
                case .confirmAudience:
                    ComposeRadiusMailingAudienceConfirmationView(viewModel: viewModel)
                case .confirmSend:
                    ComposeRadiusMailingConfirmSendView(viewModel: viewModel)
                case .radiusSent:
                    ComposeRadiusMailingSentView()
                }
            }
            .onAppear {
                viewModel.getRadiusMailingCoverArtOptions()
            }
            .alert(isPresented: $showingAlert) {
                switch alertType {
                case .requiredAddressFieldsEmpty:
                    return Alert(title: Text("Please Select an Address of Last Sale"))
                case .requiredMergeFieldsFieldsEmpty:
                    return Alert(title: Text("Please Fill in All Merge Tags"))
                }
            }
            .toolbar {
                // MARK: - Wizard Back Button
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(
                        action: {
                            guard viewModel.step == .selectLocation || viewModel.step == .confirmAudience else {
                                viewModel.step.back()
                                return
                            }
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    ) {
                        if viewModel.step != .radiusSent {
                            if viewModel.step != .confirmAudience {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            } else {
                                Text("Campaigns")
                            }
                        }
                    }
                }
                // MARK: - Wizard Next / Finish Button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(
                        action: {
                            guard locationFieldIsNotEmpty() else {
                                alertType = .requiredAddressFieldsEmpty
                                showingAlert = true
                                return
                            }
                            if viewModel.step == .selectLocation && viewModel.selectedRadiusMailing == nil {
                                viewModel.createRadiusMailing { newMailing in
                                    guard newMailing != nil else { return }
                                }
                            } else if viewModel.selectedRadiusMailing != nil {
                                viewModel.updateRadiusMailingData(for: .location) { updatedMailing in
                                    guard updatedMailing != nil else { return }
                                }
                            }

                            if viewModel.step == .selectCard {
                                viewModel.updateRadiusMailingData(for: .cover, with:
                                                                    OutgoingRadiusMailing(
                                                                        layoutTemplateID: viewModel.selectedCoverArtID,
                                                                        multiTouchTopicID: nil,
                                                                        templateOneBody: nil,
                                                                        templateTwoBody: nil,
                                                                        mergeVars: nil,
                                                                        touchDuration: nil,
                                                                        touchDurationConfirmation: nil
                                                                    )) { updatedMailing in
                                    guard updatedMailing != nil else { return }
                                }
                            }

                            guard noMissingMergeVars() else {
                                alertType = .requiredMergeFieldsFieldsEmpty
                                showingAlert = true
                                return
                            }

                            if viewModel.step == .chooseTopic {
                                let mergeVars = viewModel.touch1MergeVars.merging(viewModel.touch2MergeVars, uniquingKeysWith: { (first, _) in first })

                                viewModel.updateRadiusMailingData(for: .topic, with:
                                                                    OutgoingRadiusMailing(
                                                                        layoutTemplateID: nil,
                                                                        multiTouchTopicID: viewModel.topicSelectionID,
                                                                        templateOneBody: viewModel.touch1Body,
                                                                        templateTwoBody: viewModel.touch2Body,
                                                                        mergeVars: mergeVars,
                                                                        touchDuration: viewModel.numOfWeeksSelection,
                                                                        touchDurationConfirmation: nil)) { updatedMailing in
                                    guard updatedMailing != nil else { return }
                                }
                            }

                            if viewModel.step == .confirmSend {
                                viewModel.updateRadiusMailingData(for: .list, with:
                                                                    OutgoingRadiusMailing(
                                                                        layoutTemplateID: nil,
                                                                        multiTouchTopicID: nil,
                                                                        templateOneBody: nil,
                                                                        templateTwoBody: nil,
                                                                        mergeVars: nil,
                                                                        touchDuration: nil,
                                                                        touchDurationConfirmation: viewModel.numOfWeeksSelection)) { updatedMailing in
                                    guard updatedMailing != nil else { return }
                                }
                            }

                            guard viewModel.step == .audienceProcessing || viewModel.step == .radiusSent  else {
                                viewModel.step.next()
                                return
                            }
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    ) {
                        HStack(spacing: 6) {
                            if viewModel.step == .confirmSend {
                                Text("Confirm")
                            } else if viewModel.step == .radiusSent {
                                Text("Campaigns")
                            } else {
                                viewModel.step == .confirmAudience ? Text("Confirm Listing") :
                                    viewModel.step != .audienceProcessing ? Text(viewModel.step == .confirmAndProcess ? "Confirm" : "Next") : Text("Campaigns")
                                viewModel.step != .confirmAndProcess && viewModel.step != .audienceProcessing ? Image(systemName: "chevron.right") : nil
                            }
                        }
                    }.disabled(viewModel.mailingArt.filter({ $0.imageUrl != nil && $0.id != nil }).count < 1 && viewModel.step == .selectCard)
                }
            }
            .navigationBarTitle(Text(viewModel.step.rawValue), displayMode: .inline)
        }
    }

    private func noMissingMergeVars() -> Bool {
        guard  viewModel.step == .chooseTopic else {
            return true
        }

        return (Array(viewModel.touch1MergeVars.keys).filter { viewModel.touch1MergeVars[$0]!.isEmpty }.count == 0 ||
                    Array(viewModel.touch2MergeVars.keys).filter { viewModel.touch2MergeVars[$0]!.isEmpty }.count == 0)
    }

    private func locationFieldIsNotEmpty() -> Bool {
        guard  viewModel.step == .selectLocation else {
            return true
        }

        return !viewModel.locationEntry.isEmpty
    }
}
// MARK: - ComposeRadiusMailingSelectLocationView
struct ComposeRadiusMailingSelectLocationView: View {
    @ObservedObject var viewModel: ComposeRadiusMailingViewModel

    init(viewModel: ComposeRadiusMailingViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        let locationEntryBinding = Binding<String>(
            get: {
                viewModel.locationEntry
            }, set: {
                viewModel.locationEntry = $0
                viewModel.getPlacesFromQuery(locationQuery: $0)
            })

        VStack {
            GoogleMapsView(
                coordinates: (viewModel.latitude, viewModel.longitude),
                locationSelected: locationEntryIsPopulated(),
                zoom: locationEntryIsPopulated() ? 15.0 : 10.0
            )

            VStack(alignment: .leading, spacing: 15) {
                Text("Enter the address of the property")
                TextField("", text: locationEntryBinding)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .border(Color.black)
                    .textContentType(.fullStreetAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                if locationEntryIsPopulated() {
                    Text("Address Line 1")
                    TextField("", text: $viewModel.selectedLocationAddress1)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .border(Color.black)
                        .textContentType(.fullStreetAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    Text("Address Line 2")
                    TextField("", text: $viewModel.selectedLocationAddress2)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .border(Color.black)
                        .textContentType(.fullStreetAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    HStack(spacing: 12) {
                        Text("City")
                        TextField("", text: $viewModel.selectedLocationCity)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .border(Color.black)
                            .textContentType(.fullStreetAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        Text("State")
                        TextField("", text: $viewModel.selectedLocationState)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .border(Color.black)
                            .textContentType(.fullStreetAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        Text("Zipcode")
                        TextField("", text: $viewModel.selectedLocationZipcode)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .border(Color.black)
                            .textContentType(.fullStreetAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                } else {
                    List(viewModel.places, id: \.placeID) { place in
                        Button(action: {
                            viewModel.setPlaceOnMap(for: place.placeID)
                            viewModel.locationEntry = place.attributedFullText.string
                            viewModel.resetPlacesList()
                            hideKeyboard()
                        }) {
                            Text(place.attributedFullText.string)
                                .foregroundColor(.black)
                        }
                    }.listStyle(PlainListStyle())
                }
            }.padding()
        }
        .onAppear {
            viewModel.maybeInitializeMapWithCurrentLocation()
        }
    }

    private func locationEntryIsPopulated() -> Bool {
        return viewModel.locationEntry.contains(viewModel.selectedLocationAddress1)
    }
}
// MARK: - ComposeRadiusMailingCoverArtSelectionView
struct ComposeRadiusMailingCoverArtSelectionView: View {
    @ObservedObject var viewModel: ComposeRadiusMailingViewModel

    init(viewModel: ComposeRadiusMailingViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        if (viewModel.mailingArt.filter({ $0.imageUrl != nil && $0.id != nil }).count < 1) {
            EmptyListView(message: "No stationary avaliable. Please visit the 'Stationary & Content' section " +
                            "of the Addressable.app portal to upload cover art and continue.")
        } else {
            List(viewModel.mailingArt.filter { $0.imageUrl != nil && $0.id != nil }) { coverArt in
                RadiusMailingCoverArtRow(viewModel: viewModel, coverImage: coverArt)
            }.listStyle(PlainListStyle())
        }
    }
}
// MARK: - RadiusMailingCoverArtRow
private struct RadiusMailingCoverArtRow: View {
    @ObservedObject var viewModel: ComposeRadiusMailingViewModel

    var coverImage: MailingCoverArt
    var coverImageName: String

    init(viewModel: ComposeRadiusMailingViewModel, coverImage: MailingCoverArt) {
        self.viewModel = viewModel
        self.coverImage = coverImage
        self.coverImageName = coverImage.name?.replacingOccurrences(of: "_", with: " ") ?? "Unkown"
    }

    var body: some View {
        Button(action: {
            viewModel.selectedCoverArtID = coverImage.id
        }) {
            HStack(spacing: 6) {
                CustomNote.CoverImage(
                    withURL: coverImage.imageUrl!,
                    size: 80,
                    cornerRadius: 12
                )
                Text(coverImageName)

                Spacer()

                viewModel.selectedCoverArtID == coverImage.id  ? Image(systemName: "checkmark").foregroundColor(Color.blue) : nil
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - ComposeRadiusMailingTopicSelectionView
struct ComposeRadiusMailingTopicSelectionView: View {
    @ObservedObject var viewModel: ComposeRadiusMailingViewModel

    init(viewModel: ComposeRadiusMailingViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        let topicSelectionIDBinding = Binding<Int>(
            get: {
                viewModel.topicSelectionID
            }, set: { selectedTopicID in
                viewModel.topicSelectionID = selectedTopicID
                let selectedMultiTouchTopic = viewModel.topics.filter { topic in topic.id == selectedTopicID }
                viewModel.numOfWeeksSelection = selectedMultiTouchTopic[0].touchDuration
                viewModel.getMessageTemplates(for: selectedMultiTouchTopic[0])
            })

        GeometryReader { geometry in
            ZStack(alignment: .top) {
                Color(red: 250 / 255, green: 250 / 255, blue: 250 / 255)
                    .edgesIgnoringSafeArea(.all)

                ScrollView(.vertical, showsIndicators: false) {
                    // MARK: - Choose Radius Topic
                    HStack {
                        Text("Radius Topic")
                        Picker("Choose Radius Topic", selection: topicSelectionIDBinding) {
                            ForEach(viewModel.topics) {
                                Text($0.name).tag($0.id)
                            }
                        }
                        .frame(maxWidth: geometry.size.width / 1.5)
                        .clipped()
                    }.padding(.vertical, 10)
                    // MARK: - Touch 1 + Merge Vars
                    VStack(alignment: .center, spacing: 12) {
                        Text("Touch 1").font(.title2)
                        TextEditor(text: $viewModel.touch1Body)
                            .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.1), radius: 3, x: 2, y: 2)
                            .frame(width: geometry.size.width / 1.25, height: geometry.size.height / 2)
                    }

                    ForEach(Array(viewModel.touch1MergeVars.keys), id: \.self) { mergeTagName in
                        let mergeVarsBinding = Binding<String>(
                            get: { viewModel.touch1MergeVars[mergeTagName] ?? "" }, set: { mergeTagValue in
                                viewModel.touch1MergeVars[mergeTagName] = mergeTagValue
                            })

                        VStack(alignment: .leading) {
                            Text(mergeTagName)
                            TextField("", text: mergeVarsBinding)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textContentType(.name)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        .frame(width: geometry.size.width / 1.25)
                        .padding()
                    }

                    DottedLine()
                        .stroke(style: StrokeStyle(lineWidth: 3, dash: [4]))
                        .frame(width: 1, height: 75)
                        .foregroundColor(Color(red: 0, green: 0, blue: 0, opacity: 0.3))
                        .padding()

                    // MARK: - Time Between Touches (Duration)
                    HStack {
                        Text("Time Between Touches").multilineTextAlignment(.center)
                        Picker("Time", selection: $viewModel.numOfWeeksSelection) {
                            ForEach(viewModel.weekOptions, id: \.1) { durationSelection in
                                Text(durationSelection.0).tag(durationSelection.1)
                            }
                        }
                        .frame(maxWidth: geometry.size.width / 1.5)
                        .clipped()
                    }

                    DottedLine()
                        .stroke(style: StrokeStyle(lineWidth: 3, dash: [4]))
                        .frame(width: 1, height: 75)
                        .foregroundColor(Color(red: 0, green: 0, blue: 0, opacity: 0.3))
                        .padding()

                    // MARK: - Touch 2 + Merge Vars
                    VStack(alignment: .center, spacing: 12) {
                        Text("Touch 2").font(.title2)
                        TextEditor(text: $viewModel.touch2Body)
                            .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.1), radius: 3, x: 2, y: 2)
                            .frame(width: geometry.size.width / 1.25, height: geometry.size.height / 2)
                    }

                    ForEach(Array(viewModel.touch2MergeVars.keys), id: \.self) { mergeTagName in
                        let mergeVarsBinding = Binding<String>(
                            get: { viewModel.touch2MergeVars[mergeTagName] ?? "" }, set: { mergeTagValue in
                                viewModel.touch2MergeVars[mergeTagName] = mergeTagValue
                            })

                        VStack(alignment: .leading) {
                            Text(mergeTagName)
                            TextField("", text: mergeVarsBinding)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textContentType(.name)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        .frame(width: geometry.size.width / 1.25)
                        .padding()
                    }
                }.edgesIgnoringSafeArea(.top)
            }
        }
        .onAppear {
            viewModel.getRadiusMailingMultiTouchTopics()
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

// MARK: - ComposeRadiusMailingConfirmationView
struct ComposeRadiusMailingConfirmationView: View {
    @ObservedObject var viewModel: ComposeRadiusMailingViewModel

    init(viewModel: ComposeRadiusMailingViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading) {
                    HStack(alignment: .center) {
                        Spacer()
                        CustomNote.CoverImage(
                            withURL: getSelectedImageURL(),
                            size: geometry.size.width / 3,
                            cornerRadius: 12,
                            setAsCardLayout: true
                        )
                        Spacer()
                    }.padding()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Touch 1").font(.title3).fontWeight(.bold).foregroundColor(Color(red: 126/255, green: 0, blue: 181/255))
                        Text("Will send 350 cards to 350 recipients in the vicinity of \(viewModel.locationEntry)").font(.body)
                    }.padding()

                    HStack(alignment: .center) {
                        Spacer()
                        CustomNote.CoverImage(
                            withURL: getSelectedImageURL(),
                            size: geometry.size.width / 3,
                            cornerRadius: 12,
                            setAsCardLayout: true
                        )
                        Spacer()
                    }.padding()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Touch 2").font(.title3).fontWeight(.bold).foregroundColor(Color(red: 126/255, green: 0, blue: 181/255))
                        Text("Will send 350 cards to 350 recipients in the vicinity of \(viewModel.locationEntry)").font(.body)
                    }.padding()

                    //                    VStack(alignment: .leading, spacing: 8) {
                    //                        Text("Total Cost").font(.title3).fontWeight(.semibold)
                    //                        Text("$0").font(.body)
                    //                    }.padding()

                    HStack(alignment: .center) {
                        Spacer()
                        VStack(alignment: .leading, spacing: 10) {
                            Text("What happens now?").font(.title).fontWeight(.bold).padding()
                            Text("After you confirm this order and make a payment" +
                                    " we will have one of our experts compile the most" +
                                    " suitable 350 recipients for your campaign.").font(.body).padding()
                            Text("Within 48 hours we will notify you and offer you" +
                                    " the ability to amend the list. You are then ready to send the campaign.").font(.body).padding()
                        }
                        .padding()
                        .background(Color(red: 126/255, green: 0, blue: 181/255, opacity: 0.1))
                        .cornerRadius(35)
                        .frame(width: geometry.size.width / 1.10)
                        Spacer()
                    }
                }
            }
        }
    }

    private func getSelectedImageURL() -> String {
        guard let index = viewModel.mailingArt
                .firstIndex(where: {
                    $0.id == viewModel.selectedCoverArtID
                }),
              let imageUrl = viewModel.mailingArt[index].imageUrl
        else {
            return "https://static.wixstatic.com/media/d20312_54a7d91bc5f54232952540769b5e5f4c~mv2.png/v1/fill/w_560,h_452,al_c,q_85,usm_0.66_1.00_0.01/enterprise2.webp"
        }
        return imageUrl
    }
}

// MARK: - ComposeMailingConfirmationView
struct ComposeRadiusMailingListConfirmationView: View {
    var body: some View {
        VStack(alignment: .center, spacing: 6) {
            Image("ZippyIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 250, height: 250)
            Text("Our team is now building your mailing list. You will receive a notification when the list is ready for your review. Generally 24-48 hours.")
                .padding(25)
                .multilineTextAlignment(.center)
        }
    }
}
// MARK: - ComposeRadiusMailingAudienceConfirmationView
struct ComposeRadiusMailingAudienceConfirmationView: View {
    @ObservedObject var viewModel: ComposeRadiusMailingViewModel
    @State var showingAlert = false
    @State var selectedRecipientToRemoveID: Int?

    init(viewModel: ComposeRadiusMailingViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .center, spacing: 6) {
            HStack {
                HStack {
                    Image(systemName: "person.3")
                    Text("\(viewModel.selectedRadiusMailing?.activeRecipientCount ?? 0)")
                        .font(.headline)
                }.padding()
            }
            .background(Color(red: 235/255, green: 235/255, blue: 235/255))
            .cornerRadius(50.0)
            .padding(.top, 12)

            Text("Feel free to remove any that you feel aren't suitable. They will be replaced with alternatives to ensure you get the same reach")
                .padding()
                .foregroundColor(Color(red: 0, green: 0, blue: 0, opacity: 0.5))
                .multilineTextAlignment(.center)

            List(viewModel.selectedRadiusMailing!.recipients.filter { $0.status == ListEntryStatus.active.rawValue }) { recipient in
                HStack {
                    Text("\(recipient.firstName!) \(recipient.lastName!)")
                    Spacer()
                    Button(action: {
                        showingAlert = true
                        selectedRecipientToRemoveID = recipient.id
                    }) {
                        Image(systemName: "trash").foregroundColor(.red)

                    }
                }.alert(isPresented: $showingAlert) {
                    Alert(
                        title: Text("Remove Recipient from List?"), message: Text("Are you sure you want to remove recipient from the list?"),
                        primaryButton: .default(Text("Confirm")) {
                            guard selectedRecipientToRemoveID != nil else { return }
                            viewModel.updateListEntry(for: selectedRecipientToRemoveID!, with: ListEntryStatus.rejected.rawValue)
                        }, secondaryButton: .cancel())
                }
            }
            .listStyle(PlainListStyle())
        }
    }
}

// MARK: - ComposeRadiusMailingConfirmSendView
struct ComposeRadiusMailingConfirmSendView: View {
    @ObservedObject var viewModel: ComposeRadiusMailingViewModel
    @State private var date = Date()
    @State private var displayDurationPicker: Bool = false
    @State private var durationEdited: Bool = false

    init(viewModel: ComposeRadiusMailingViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        let topicDurationSelectionBinding = Binding<Int>(
            get: {
                viewModel.numOfWeeksSelection
            }, set: { selectedDuration in
                viewModel.numOfWeeksSelection = selectedDuration
                displayDurationPicker = false
                durationEdited = true
            })

        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading) {
                    HStack(alignment: .center) {
                        Spacer()
                        CustomNote.CoverImage(
                            withURL: getSelectedImageURL(),
                            size: geometry.size.width / 3,
                            cornerRadius: 12,
                            setAsCardLayout: true
                        )
                        Spacer()
                    }.padding()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Touch 1").font(.title).fontWeight(.bold)
                        Text("We will send " +
                                "\(viewModel.selectedRadiusMailing!.activeRecipientCount) " +
                                "cards to \(viewModel.selectedRadiusMailing!.activeRecipientCount) " +
                                "recipients in the vicinity of ")
                            .font(.subheadline)
                            .foregroundColor(Color(red: 0, green: 0, blue: 0, opacity: 0.5))
                            + Text(
                                "\(viewModel.selectedRadiusMailing!.subjectListEntry.siteAddressLine1), " +
                                    "\(viewModel.selectedRadiusMailing!.subjectListEntry.siteAddressLine2) " +
                                    "\(viewModel.selectedRadiusMailing!.subjectListEntry.siteCity), " +
                                    "\(viewModel.selectedRadiusMailing!.subjectListEntry.siteState)"
                            )
                            .font(.subheadline)
                            .foregroundColor(Color(red: 0, green: 0, blue: 0, opacity: 0.5))
                    }.padding()

                    HStack(alignment: .center) {
                        Spacer()
                        CustomNote.CoverImage(
                            withURL: getSelectedImageURL(),
                            size: geometry.size.width / 3,
                            cornerRadius: 12,
                            setAsCardLayout: true
                        )
                        Spacer()
                    }.padding()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Touch 2").font(.title).fontWeight(.bold)
                        HStack(spacing: 24) {
                            if let duration = viewModel.selectedRadiusMailing!.topicDuration {
                                if !displayDurationPicker {
                                    Text("\(durationEdited ? viewModel.numOfWeeksSelection : duration) weeks later").font(.subheadline).foregroundColor(Color(red: 0, green: 0, blue: 0, opacity: 0.3))
                                    Button(action: {
                                        // Display Duration Picker
                                        viewModel.numOfWeeksSelection = duration
                                        displayDurationPicker = true
                                    }) {
                                        Text("Edit").font(.subheadline).underline().foregroundColor(Color(red: 0, green: 0, blue: 0, opacity: 0.5))
                                    }
                                } else {
                                    VStack(alignment: .center) {
                                        Picker("Time", selection: topicDurationSelectionBinding) {
                                            ForEach(viewModel.weekOptions, id: \.1) { durationSelection in
                                                Text(durationSelection.0.replacingOccurrences(of: "Weeks", with: "")).tag(durationSelection.1)
                                            }
                                        }.pickerStyle(SegmentedPickerStyle())
                                        .frame(maxWidth: geometry.size.width / 1.5)
                                        .clipped()
                                        Text("(Weeks)").font(.subheadline)
                                    }
                                }
                            }
                        }
                        Text("We will send " +
                                "\(viewModel.selectedRadiusMailing!.activeRecipientCount) " +
                                "cards to \(viewModel.selectedRadiusMailing!.activeRecipientCount) " +
                                "recipients in the vicinity of ")
                            .font(.subheadline)
                            .foregroundColor(Color(red: 0, green: 0, blue: 0, opacity: 0.5))
                            + Text(
                                "\(viewModel.selectedRadiusMailing!.subjectListEntry.siteAddressLine1), " +
                                    "\(viewModel.selectedRadiusMailing!.subjectListEntry.siteAddressLine2) " +
                                    "\(viewModel.selectedRadiusMailing!.subjectListEntry.siteCity)," +
                                    " \(viewModel.selectedRadiusMailing!.subjectListEntry.siteState)"
                            )
                            .font(.subheadline)
                            .foregroundColor(Color(red: 0, green: 0, blue: 0, opacity: 0.5))
                    }.padding()
                }
            }
        }
    }

    private func getSelectedImageURL() -> String {
        guard let index = viewModel.mailingArt
                .firstIndex(where: { $0.id == viewModel.selectedRadiusMailing?.layoutTemplate?.id }),
              let imageUrl = viewModel.mailingArt[index].imageUrl
        else {
            return "https://static.wixstatic.com/media/d20312_54a7d91bc5f54232952540769b5e5f4c~mv2.png/v1/fill/w_560,h_452,al_c,q_85,usm_0.66_1.00_0.01/enterprise2.webp"
        }
        return imageUrl
    }
}

// MARK: - ComposeRadiusMailingSentView
struct ComposeRadiusMailingSentView: View {
    var body: some View {
        VStack(alignment: .center, spacing: 6) {
            Image("ZippyIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 250, height: 250)
            Text("Your Radius mailing is completed. You will receive a notification when the mailing is sent in the next 1-2 days.")
                .padding(25)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - EmptyListView
struct EmptyListView: View {
    var message: String

    var body: some View {
        VStack(alignment: .center, spacing: 6) {
            Text(message)
                .padding(25)
                .multilineTextAlignment(.center)
        }
    }
}

struct ComposeRadiusMailingView_Previews: PreviewProvider {
    static var previews: some View {
        ComposeRadiusMailingView(viewModel: ComposeRadiusMailingViewModel(selectedRadiusMailing: nil))
    }
}
