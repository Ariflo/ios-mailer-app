//
//  ComposeRadiusViewModel.swift
//  Addressable
//
//  Created by Ari on 2/12/21.
//

// swiftlint:disable force_unwrapping type_body_length file_length

import SwiftUI
import Combine
import GooglePlaces

class ComposeRadiusViewModel: NSObject, ObservableObject {
    private let apiService: ApiService
    private var disposables = Set<AnyCancellable>()
    private let locationManager = CLLocationManager()
    private var placesClient = GMSPlacesClient.shared()

    @Published var places: [GMSAutocompletePrediction] = []
    @Published var location: CLLocation? {
        willSet { objectWillChange.send() }
    }

    var latitude: CLLocationDegrees = 0
    var longitude: CLLocationDegrees = 0

    @Published var selectedLocationAddress1 = ""
    @Published var selectedLocationAddress2 = ""
    @Published var selectedLocationCity = ""
    @Published var selectedLocationState = ""
    @Published var selectedLocationZipcode = ""

    @Published var step = ComposeRadiusSteps.selectLocation
    @Published var locationEntry: String = ""
    @Published var selectedCoverImageID: Int = 0
    @Published var mailingCoverImages: [Int: MailingCoverImageData] = [:]
    @Published var topics: [MultiTouchTopic] = []
    @Published var topicSelectionID: Int = 0
    @Published var touchOneBody: String = "Write your message here..."
    @Published var touchTwoBody: String = "Write your message here..."
    @Published var touchOneTemplate: MessageTemplate?
    @Published var touchTwoTemplate: MessageTemplate?
    @Published var touchOneTemplateMergeVariables: [String: String] = [:]
    @Published var touchTwoTemplateMergeVariables: [String: String] = [:]
    @Published var touchOneMailing: Mailing?
    @Published var touchTwoMailing: Mailing?

    @Published var loadingImages: Bool = false
    @Published var loadingTopics: Bool = false
    @Published var isSelectingCoverImage: Bool = false
    @Published var canAfford: Bool = true

    // In the case that call to API fails set data tree search criteria defaults here
    @Published var dataTreeSearchCriteria = DataTreeSearchCriteria(
        minValue: 450000,
        maxValue: 2000000,
        includeValue: true,
        minBedCount: 0,
        maxBedCount: 4,
        includeBedCount: false,
        minBathCount: 0,
        maxBathCount: 4,
        includeBathCount: false,
        minBuildingArea: 800,
        maxBuildingArea: 5000,
        includeBuildingArea: false,
        minYearBuilt: 1950,
        maxYearBuilt: 2015,
        includeYearBuilt: false,
        minLotSize: 1000,
        maxLotSize: 100000,
        includeLotSize: false,
        landUseSingleFamily: true,
        landUseMultiFamily: false,
        landUseCondos: true,
        landUseVacantLot: false,
        minPercentEquity: 20,
        maxPercentEquity: 100,
        includePercentEquity: true,
        minYearsOwned: 3,
        maxYearsOwned: 20,
        includeYearsOwned: true,
        ownerOccupiedOccupied: true,
        ownerOccupiedAbsentee: true,
        zipcodes: "",
        includeZipcodes: false,
        city: "",
        includeCities: false)

    @Published var isEditingTargetDropDate: Bool = false
    @Published var touchOneInsideCardImageData: Data?
    @Published var touchTwoInsideCardImageData: Data?
    @Published var numActiveRecipients: Int = 0
    var subscribedChannels: [String: Set<Int>] = [:]
    var subscribedSubjectMailingIds = Set<Int>()

    var selectedDropDate: String = ""
    let mailingTouches: [Mailing] = []

    init(provider: DependencyProviding, selectedMailing: Mailing?) {
        apiService = provider.register(provider: provider)

        super.init()

        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()

        if selectedMailing != nil {
            // In the case that the selected radius mailing is the touch two mailing,
            // extract touch one mailing and set it as the selected mailing
            if let relatedTouchMailing = selectedMailing!.relatedMailing {
                self.getRadiusMailing(with: relatedTouchMailing.id) { relatedRadiusMailing in
                    guard relatedRadiusMailing != nil else { return }

                    if let touchOneMailing = selectedMailing?.relatedMailing?.parentMailingID == nil ?
                        relatedRadiusMailing : selectedMailing {
                        self.populateForm(with: touchOneMailing)
                    }
                }
            } else {
                self.populateForm(with: selectedMailing!)
            }
        }

        DispatchQueue.main.async {
            self.getPlacesFromQuery(locationQuery: self.locationEntry) {[weak self] places in
                guard let self = self else { return }
                guard places != nil else { return }

                var selectedMailingPlace: GMSAutocompletePrediction?
                for place in places! {
                    if self.locationEntry.contains(place.attributedPrimaryText.string) {
                        selectedMailingPlace = place
                        break
                    }
                }
                guard selectedMailingPlace != nil else { return }
                self.setPlaceOnMap(for: selectedMailingPlace!.placeID)
            }
        }
    }

    func populateForm(with radiusMailing: Mailing) {
        guard radiusMailing.subjectListEntry != nil else { return }

        // Initialize TargetDropDate to current day + ten
        if let datePlusTen = Calendar.current.date(byAdding: .day, value: 10, to: Date()) {
            setSelectedDropDate(selectedDate: datePlusTen)
        }

        touchOneMailing = radiusMailing
        selectedCoverImageID = radiusMailing.layoutTemplate?.id ?? 0
        topicSelectionID = radiusMailing.topicSelectionID ?? 0
        locationEntry = "\(radiusMailing.subjectListEntry!.siteAddressLine1), " +
            "\(radiusMailing.subjectListEntry!.siteAddressLine2 ?? "") " +
            "\(radiusMailing.subjectListEntry!.siteCity), " +
            "\(radiusMailing.subjectListEntry!.siteState), " +
            "\(radiusMailing.subjectListEntry!.siteZipcode) "
        selectedLocationAddress1 = radiusMailing.subjectListEntry!.siteAddressLine1
        selectedLocationAddress2 = radiusMailing.subjectListEntry!.siteAddressLine2 ?? " "
        selectedLocationCity = radiusMailing.subjectListEntry!.siteCity
        selectedLocationState = radiusMailing.subjectListEntry!.siteState
        selectedLocationZipcode = radiusMailing.subjectListEntry!.siteZipcode
    }

    func maybeInitializeMapWithCurrentLocation() {
        latitude = location?.coordinate.latitude ?? 0
        longitude = location?.coordinate.longitude ?? 0
    }

    func getPlacesFromQuery(
        locationQuery: String,
        completion: @escaping (_ places: [GMSAutocompletePrediction]?) -> Void = { _ in }
    ) {
        let filter = GMSAutocompleteFilter()
        filter.type = .address

        placesClient.findAutocompletePredictions(
            fromQuery: locationQuery,
            filter: filter,
            sessionToken: GMSAutocompleteSessionToken.init()
        ) {[weak self] results, error in
            if let error = error {
                print("Autocomplete error: \(error)")
                completion(nil)
                return
            }
            if let results = results {
                self?.places = results
                completion(results)
            }
        }
    }

    func setPlaceOnMap(for placeID: String) {
        placesClient.lookUpPlaceID(placeID) {[weak self] place, error in
            if let error = error {
                print("lookup place id query error: \(error.localizedDescription)")
                return
            }

            guard let place = place else {
                print("No place details for \(placeID)")
                return
            }

            let streetNumber = place.addressComponents?.first { $0.types.contains("street_number") }?.name ?? ""
            let streetName = place.addressComponents?.first { $0.types.contains("route") }?.name ?? ""

            self?.latitude = place.coordinate.latitude
            self?.longitude = place.coordinate.longitude
            self?.selectedLocationAddress1 = "\(streetNumber) \(streetName)"
            self?.selectedLocationCity = place.addressComponents?.first {
                $0.types.contains("locality")
            }?.shortName ?? ""
            self?.selectedLocationState = place.addressComponents?.first {
                $0.types.contains("administrative_area_level_1")
            }?.shortName ?? ""
            self?.selectedLocationZipcode = place.addressComponents?.first {
                $0.types.contains("postal_code")
            }?.name ?? ""
        }
    }

    func resetPlacesList() {
        places = []
    }

    func getRadiusMailingCoverImageOptions() {
        loadingImages = true
        apiService
            .getMailingCoverImages()
            .map { resp in resp.mailingCoverImages
                .filter { $0.mailingCoverImage.cardFrontImageUrl != nil }
                .map { $0.mailingCoverImage }
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] value in
                    guard let self = self else { return }
                    switch value {
                    case .failure(let error):
                        print("getRadiusMailingCoverImageOptions() receiveCompletion error: \(error)")
                        self.mailingCoverImages = [:]
                        self.loadingImages = false
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] mailingCoverImages in
                    guard let self = self else { return }
                    self.getMailingCoverImageData(for: mailingCoverImages)
                })
            .store(in: &disposables)
    }

    private func getMailingCoverImageData(for coverImages: [MailingCoverImage]) {
        guard !coverImages.isEmpty else {
            self.loadingImages = false
            return
        }
        for image in coverImages {
            guard let urlString = image.cardFrontImageUrl,
                  let url = URL(string: urlString) else { continue }

            let task = URLSession.shared.dataTask(with: url) { data, _, _ in
                guard let data = data else { return }

                DispatchQueue.main.async {[weak self] in
                    guard let self = self else { return }
                    self.mailingCoverImages[image.id] = MailingCoverImageData(
                        id: image.id,
                        image: image,
                        imageData: data)
                    // Present images when they've all loaded
                    if self.mailingCoverImages.keys.count == coverImages.count {
                        self.loadingImages = false

                        if self.selectedCoverImageID == 0 {
                            self.selectedCoverImageID = self.mailingCoverImages.keys.first {
                                self.mailingCoverImages[$0]!.image.isDefaultCoverImage
                            } ?? 0
                        }
                    }
                }
            }
            task.resume()
        }
    }

    func getSelectedImageData() -> Data {
        guard let selectedImage = mailingCoverImages.values.first(where: { $0.id == selectedCoverImageID }) else {
            return Data()
        }

        return selectedImage.imageData
    }

    func getInsideCardImageData(for touch: AddressableTouch, url: String) {
        guard let url = URL(string: url) else { return }

        let task = URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { return }

            DispatchQueue.main.async {[weak self] in
                guard let self = self else { return }
                if touch == .touchOne {
                    self.touchOneInsideCardImageData = data
                } else {
                    self.touchTwoInsideCardImageData = data
                }
            }
        }
        task.resume()
    }

    func getRadiusMailingMultiTouchTopics() {
        loadingTopics = true
        apiService.getMultiTouchTopics()
            .map { resp in
                resp.multiTouchTopics.map { $0.multiTouchTopic }
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] value in
                    guard let self = self else { return }
                    switch value {
                    case .failure(let error):
                        print("getRadiusMailingMultiTouchTopics() receiveCompletion error: \(error)")
                        self.topics = []
                        self.topicSelectionID = 0
                        self.loadingTopics = false
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] multiTouchTopics in
                    guard let self = self else { return }
                    guard !multiTouchTopics.isEmpty else {
                        self.loadingTopics = false
                        self.topics = []
                        self.topicSelectionID = 0
                        return
                    }
                    self.topics = multiTouchTopics
                    self.loadingTopics = false
                    guard self.touchOneMailing?.topicSelectionID == nil else {
                        if let mailing = self.touchOneMailing,
                           let topicSelectionID = mailing.topicSelectionID {
                            self.topicSelectionID = topicSelectionID

                            if let previouslySelectedTopic = multiTouchTopics.first(where: {
                                $0.id == topicSelectionID
                            }) {
                                self.getMessageTemplates(for: previouslySelectedTopic)
                            } else {
                                print("Could not find previouslySelectedTopic in getRadiusMailingMultiTouchTopics()")
                            }
                        }
                        return
                    }
                    self.topicSelectionID = self.topics[0].id
                    self.getMessageTemplates(for: self.topics[0])
                })
            .store(in: &disposables)
    }

    func getMessageTemplates(for topic: MultiTouchTopic) {
        // Reset merge varibles with every update
        touchOneTemplateMergeVariables = [:]
        touchTwoTemplateMergeVariables = [:]

        getTopicsMessageTemplate(for: 1, with: topic.touchOneTemplateID)
        getTopicsMessageTemplate(for: 2, with: topic.touchTwoTemplateID)
    }

    func getTopicsMessageTemplate(
        for touch: Int,
        with templateId: Int,
        completion: @escaping (MessageTemplate?) -> Void = { _ in }
    ) {
        if let mailingId = touchOneMailing?.id {
            apiService.getMessageTemplate(for: templateId, with: mailingId)
                .map { resp in
                    resp.messageTemplate
                }
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] value in
                        guard let self = self else { return }
                        switch value {
                        case .failure(let error):
                            print("getTopicsMessageTemplate(" +
                                    "for touch: \(touch), with templateId: \(templateId) " +
                                    "receiveCompletion error: \(error)")
                            if touch == 1 {
                                self.touchOneTemplate = nil
                                self.touchOneBody = "Write your message here..."
                                self.touchOneTemplateMergeVariables = [:]
                            } else {
                                self.touchTwoTemplate = nil
                                self.touchTwoBody = "Write your message here..."
                                self.touchTwoTemplateMergeVariables = [:]
                            }
                            completion(nil)
                        case .finished:
                            break
                        }
                    },
                    receiveValue: { [weak self] topicsMessageTemplate in
                        guard let self = self else { return }
                        if touch == 1 {
                            self.touchOneTemplate = topicsMessageTemplate
                            self.touchOneBody = topicsMessageTemplate.body
                            self.touchOneTemplateMergeVariables = self.touchOneTemplateMergeVariables.merging(
                                topicsMessageTemplate.mergeVars.mapValues { $0 ?? "" }) { first, _ in first }
                        } else {
                            self.touchTwoTemplate = topicsMessageTemplate
                            self.touchTwoBody = topicsMessageTemplate.body
                            self.touchTwoTemplateMergeVariables = self.touchTwoTemplateMergeVariables.merging(
                                topicsMessageTemplate.mergeVars.mapValues { $0 ?? "" }) { first, _ in first }

                            self.loadingTopics = false
                        }
                        completion(topicsMessageTemplate)
                    })
                .store(in: &disposables)
        }
    }

    func createRadiusMailing(completion: @escaping (_ updatedMailing: Mailing?) -> Void) {
        guard let encodedNewRadiusData = try? JSONEncoder().encode(
            OutgoingRadiusMailingSiteWrapper(
                subjectListEntry:
                    OutgoingSubjectListEntry(
                        siteAddressLine1: selectedLocationAddress1,
                        siteAddressLine2: selectedLocationAddress2,
                        siteCity: selectedLocationCity,
                        siteState: selectedLocationState,
                        siteZipcode: selectedLocationZipcode,
                        latitude: String(latitude),
                        longitude: String(longitude),
                        status: "active_radius_subject"),
                dataTreeSearch: dataTreeSearchCriteria
            )
        ) else {
            print("New Radius Mailing Encoding Error")
            return
        }

        apiService.createNewRadiusMailing(encodedNewRadiusData)
            .map { resp in
                resp.radiusMailing
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { value in
                    switch value {
                    case .failure(let error):
                        print("createNewRadiusMailing(), receiveCompletion error: \(error)")
                        completion(nil)
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] newRadiusMailing in
                    guard let self = self else { return }
                    self.touchOneMailing = newRadiusMailing
                    completion(newRadiusMailing)
                })
            .store(in: &disposables)
    }

    func updateRadiusMailingData(
        for radiusMailingComponent: RadiusMailingComponent,
        completion: @escaping (_ updatedMailing: Mailing?) -> Void
    ) {
        guard let radiusMailingID = touchOneMailing?.id else {
            print("No Radius Mailing Selected")
            return
        }

        apiService.updateRadiusMailing(
            for: radiusMailingComponent,
            with: radiusMailingID,
            getEncodedUpdateRadiusMailingData(component: radiusMailingComponent)
        )
        .map { resp in
            resp.radiusMailing
        }
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { value in
                switch value {
                case .failure(let error):
                    print("updateRadiusMailing(), receiveCompletion error: \(error)")
                    completion(nil)
                case .finished:
                    break
                }
            },
            receiveValue: { mailing in
                self.touchOneMailing = mailing
                completion(mailing)
            })
        .store(in: &disposables)
    }

    private func getEncodedUpdateRadiusMailingData(component: RadiusMailingComponent) -> Data? {
        switch component {
        case .location:
            guard let updateData = try? JSONEncoder().encode(
                OutgoingRadiusMailingSiteWrapper(subjectListEntry:
                                                    OutgoingSubjectListEntry(
                                                        siteAddressLine1: selectedLocationAddress1,
                                                        siteAddressLine2: selectedLocationAddress2,
                                                        siteCity: selectedLocationCity,
                                                        siteState: selectedLocationState,
                                                        siteZipcode: selectedLocationZipcode,
                                                        latitude: String(latitude),
                                                        longitude: String(longitude),
                                                        status: "active_radius_subject"),
                                                 dataTreeSearch: dataTreeSearchCriteria
                )
            ) else {
                print("Update Radius Mailing LOCATION Encoding Error")
                return nil
            }
            return updateData
        case .cover:
            guard let updateData = try? JSONEncoder().encode(
                OutgoingMailingCoverArtWrapper(
                    cover: OutgoingMailingCoverArtData(layoutTemplateID: selectedCoverImageID)
                )
            ) else {
                print("Update Radius Mailing COVER Encoding Error")
                return nil
            }
            return updateData
        case .topic:
            guard let updateData = try? JSONEncoder().encode(
                OutgoingRadiusMailingTopicWrapper(
                    topic: OutgoingRadiusMailingTopicData(multiTouchTopicID: topicSelectionID),
                    topicTemplate: OutgoingRadiusMailingTopicTemplateData(
                        templateOneBody: touchOneBody,
                        templateTwoBody: touchTwoBody),
                    mergeVars: touchOneTemplateMergeVariables.merging(
                        touchTwoTemplateMergeVariables, uniquingKeysWith: { first, _ in first }))
            ) else {
                print("Update Radius Mailing TOPIC Encoding Error")
                return nil
            }
            return updateData
        case .list:
            // List approval requires no data to update
            return Data()
        case .targetDate:
            guard let updateData = try? JSONEncoder().encode(
                OutgoingRadiusMailingTargetDropDate(radiusMailing: TargetDropDate(tagetDropDate: selectedDropDate))
            ) else {
                print("Update Radius Mailing LIST Encoding Error")
                return nil
            }
            return updateData
        }
    }

    private func getRadiusMailing(with id: Int, completion: @escaping (Mailing?) -> Void) {
        apiService.getSelectedMailing(for: id)
            .map { $0.mailing }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { value in
                    switch value {
                    case .failure(let error):
                        completion(nil)
                        print("getRadiusMailing(for id: \(id)), receiveCompletion error: \(error)")
                    case .finished:
                        break
                    }
                },
                receiveValue: {radiusMailing in
                    completion(radiusMailing)
                })
            .store(in: &disposables)
    }

    private func getTouch() -> AddressableTouch {
        return touchOneInsideCardImageData == nil ? .touchOne : .touchTwo
    }

    func updateMessageTemplate(
        for touch: AddressableTouch,
        templateId: Int,
        with newBody: String,
        completion: @escaping (MessageTemplate?) -> Void
    ) {
        guard let mailingId = touchOneMailing?.id else { return }
        guard let encodedMessageTemplateData = try? JSONEncoder().encode(
            OutgoingMessageTemplateWrapper(
                mailingId: mailingId,
                messageTemplate: OutgoingMessageTemplate(title: nil, body: newBody)
            )
        ) else {
            print("Update Message Template Encoding Error")
            return
        }

        apiService.updateMessageTemplate(for: templateId, encodedMessageTemplateData)
            .map { resp in
                resp.messageTemplate
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { value in
                    switch value {
                    case .failure(let error):
                        print("updateMessageTemplate(" +
                                "for id: \(templateId), with newBody: \(newBody), receiveCompletion error: \(error)")
                        completion(nil)
                    case .finished:
                        break
                    }
                },
                receiveValue: { updatedMessageTemplate in
                    completion(updatedMessageTemplate)
                })
            .store(in: &disposables)
    }

    func setSelectedDropDate(selectedDate: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        selectedDropDate = dateFormatter.string(from: selectedDate)
    }

    func getDataTreeDefaultSearchCriteria() {
        apiService.getDefaultDataTreeSearchCriteria()
            .map { $0.dataTreeSearchCriteria }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { value in
                    switch value {
                    case .failure(let error):
                        print("getDataTreeDefaultSearchCriteria() receiveCompletion error: \(error)")
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] defaultCriteria in
                    guard let self = self else { return }
                    self.dataTreeSearchCriteria = defaultCriteria
                })
            .store(in: &disposables)
    }

    func connectToSocket() {
        if let keyStoreUser = KeyChainServiceUtil.shared[userData],
           let userData = keyStoreUser.data(using: .utf8),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            apiService.connectToWebSocket(
                userToken: user.authenticationToken
            ) {[weak self] data in
                guard let self = self else { return }
                guard let streamData = data else {
                    print("No data to confirm connection to socket")
                    return
                }
                self.logSocketPing(data: streamData)
                self.maybeSubscribeToChannels(with: streamData)
            }
        }
    }

    private func extractData(from data: Data) {
        for channel in RadiusSocketChannels.allCases {
            switch channel {
            case .insideCardImage:
                guard let socketResponseData = try? JSONDecoder()
                        .decode(InsideCardImageSubscribedResponse.self, from: data) else {
                    #if DEBUG || STAGING
                    print("InsideCardImageSubscribedResponse decoding Error")
                    #endif
                    continue
                }
                if let imageDataResponse = socketResponseData.message,
                   let relevantMailingId = touchTwoMailing == nil ? touchOneMailing?.id : touchTwoMailing?.id {
                    if relevantMailingId == imageDataResponse.mailingId {
                        getInsideCardImageData(
                            for: touchTwoMailing == nil ? .touchOne : .touchTwo,
                            url: imageDataResponse.cardInsidePreviewUrl
                        )
                    }
                }
            case .relatedMailing:
                guard let socketResponseData = try? JSONDecoder()
                        .decode(RelatedMailingSubscribedResponse.self, from: data) else {
                    #if DEBUG || STAGING
                    print("RelatedMailingSubscribedResponse decoding Error")
                    #endif
                    continue
                }
                if let radiusMailingResponse = socketResponseData.message {
                    DispatchQueue.main.async {
                        guard radiusMailingResponse.status == nil  else {
                            if radiusMailingResponse.status == .paymentRequired {
                                self.canAfford = false
                            }
                            return
                        }
                        self.touchTwoMailing = radiusMailingResponse.radiusMailing
                    }
                }
            }
        }
    }

    private func maybeSubscribeToChannels(with data: Data) {
        if touchOneMailing?.cardInsidePreviewUrl == nil ||
            (touchTwoMailing != nil && touchTwoMailing?.cardInsidePreviewUrl == nil) {
            subscribeToChannel(channel: .insideCardImage, socketResponseData: data)
        }
        if touchTwoMailing == nil {
            subscribeToChannel(channel: .relatedMailing, socketResponseData: data)
        }
    }

    private func subscribeToChannel(
        channel: RadiusSocketChannels,
        socketResponseData: Data
    ) {
        if let mailingId = touchTwoMailing == nil ? touchOneMailing?.id : touchTwoMailing?.id {
            guard !subscribedToChannel(channel, for: mailingId) else { return }

            self.apiService.subscribe(
                command: "subscribe",
                identifier: "{\"channel\": \"\(channel.rawValue)\", \"id\": " +
                    "\"\(mailingId)\"}"
            )
            #if DEBUG || STAGING
            print("\(channel.rawValue) Socket Subscription made for mailing with " +
                    "id \(mailingId)")
            #endif
        } else {
            // Try re-subscribing
            subscribeToChannel(
                channel: channel,
                socketResponseData: socketResponseData
            )
            #if DEBUG || STAGING
            print("\(channel.rawValue) Socket Subscription re-attempted for mailing")
            #endif
            return
        }
    }

    private func subscribedToChannel(_ channel: RadiusSocketChannels, for mailingId: Int) -> Bool {
        return ((subscribedChannels[channel.rawValue]?.contains(mailingId)) != nil)
    }

    func disconnectFromSocket() {
        apiService.disconnectFromWebSocket()
    }

    func logSocketPing(data: Data) {
        do {
            let socketPingResponseData = try JSONDecoder().decode(
                MessageSubscribePingResponse.self,
                from: data
            )

            switch socketPingResponseData.type {
            case .confirm:
                if let identifier = socketPingResponseData.identifier {
                    for channelName in RadiusSocketChannels.allCases where identifier.contains(channelName.rawValue) {
                        #if DEBUG || STAGING
                        print("User Successfully Subscribed to \(channelName) -> " +
                                "socketResponseData: \(socketPingResponseData)")
                        #endif
                        if let mailingId = touchTwoMailing == nil ? touchOneMailing?.id : touchTwoMailing?.id {
                            print("MAILING ID for touch \(touchTwoMailing == nil ? 1 : 2) ID => \(mailingId)")
                            self.subscribedSubjectMailingIds.insert(mailingId)
                            self.subscribedChannels[channelName.rawValue] = self.subscribedSubjectMailingIds
                        }
                    }
                }
            case .ping:
                #if DEBUG || STAGING
                print("Socket Ping -> socketResponseData: \(socketPingResponseData)")
                #endif
            case .welcome:
                #if DEBUG || STAGING
                print("User Successfully Connected to Socket -> " +
                        "socketResponseData: \(socketPingResponseData)")
                #endif
            case .none:
                #if DEBUG || STAGING
                print("Unknown -> socketResponseData: \(socketPingResponseData)")
                #endif
            }
        } catch {
            #if DEBUG || STAGING
            print("connectToSocket MessageSubscribePingResponse decoding error: \(error)")
            #endif
            // Extract data that is not MessageSubscribePingResponse
            self.extractData(from: data)
        }
    }
}

extension ComposeRadiusViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.location = location
    }
}
