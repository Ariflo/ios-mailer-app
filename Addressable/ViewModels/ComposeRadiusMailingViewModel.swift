//
//  ComposeRadiusMailingViewModel.swift
//  Addressable
//
//  Created by Ari on 2/12/21.
//

// swiftlint:disable type_body_length

import SwiftUI
import Combine
import GooglePlaces

class ComposeRadiusMailingViewModel: NSObject, ObservableObject, Identifiable {
    private let addressableDataFetcher = AddressableDataFetcher()
    private var disposables = Set<AnyCancellable>()
    private let locationManager = CLLocationManager()
    private var placesClient = GMSPlacesClient.shared()

    @Published var places = [GMSAutocompletePrediction]()
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

    @Published var step = ComposeRadiusMailingSteps.selectLocation
    @Published var locationEntry: String = ""
    @Published var selectedCoverImageID: Int = 0
    @Published var mailingCoverImages: [Int: MailingCoverImageData] = [:]
    @Published var topics: [MultiTouchTopic] = []
    @Published var topicSelectionID: Int = 0
    @Published var touchOneBody: String = "Write your message here..."
    @Published var touchTwoBody: String = "Write your message here..."
    @Published var shouldUpdateTouchOneTemplate: Bool = false
    @Published var touchOneTemplate: MessageTemplate?
    @Published var touchTwoTemplate: MessageTemplate?
    @Published var touchOneTemplateMergeVariables: [String: String] = [:]
    @Published var touchTwoTemplateMergeVariables: [String: String] = [:]
    @Published var touchOneMailing: RadiusMailing?
    @Published var touchTwoMailing: RadiusMailing?

    @Published var loadingImages: Bool = false
    @Published var loadingTopics: Bool = false
    @Published var loadingInsideCardPreview: Bool = true

    // In the case that call to API fails set data tree search criteria defaults here
    @Published var dataTreeSearchCriteria: DataTreeSearchCriteria = DataTreeSearchCriteria(
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
        landUseCondos: false,
        landUseVacantLot: false,
        minPercentEquity: 20,
        maxPercentEquity: 100,
        includePercentEquity: true,
        minYearsOwned: 3,
        maxYearsOwned: 20,
        includeYearsOwned: true,
        ownerOccupiedOccupied: true,
        ownerOccupiedAbsentee: false,
        zipcodes: "",
        includeZipcodes: false,
        city: "",
        includeCities: false)

    @Published var isEditingTargetDropDate: Bool = false
    @Published var touchOneInsideCardImageData: Data?
    @Published var touchTwoInsideCardImageData: Data?

    var selectedDropDate: String = ""

    init(selectedRadiusMailing: RadiusMailing?) {
        super.init()

        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()

        if selectedRadiusMailing != nil {
            // In the case that the selected radius mailing is the touch two mailing,
            // extract touch one mailing and set it as the selected mailing
            if let relatedTouchMailing = selectedRadiusMailing!.relatedMailing {
                self.getRadiusMailing(with: relatedTouchMailing.id) { relatedRadiusMailing in
                    guard relatedRadiusMailing != nil else { return }

                    if let touchOneMailing = selectedRadiusMailing?.relatedMailing?.parentMailingID == nil ?
                        relatedRadiusMailing : selectedRadiusMailing {
                        self.populateForm(with: touchOneMailing)
                    }

                }
            } else {
                self.populateForm(with: selectedRadiusMailing!)
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

    func populateForm(with radiusMailing: RadiusMailing) {
        selectedDropDate = radiusMailing.targetDropDate!
        touchOneMailing = radiusMailing
        selectedCoverImageID = radiusMailing.layoutTemplate?.id ?? 0
        topicSelectionID = radiusMailing.topicSelectionID ?? 0
        locationEntry = "\(radiusMailing.subjectListEntry.siteAddressLine1), " +
            "\(radiusMailing.subjectListEntry.siteAddressLine2 ?? "") " +
            "\(radiusMailing.subjectListEntry.siteCity), " +
            "\(radiusMailing.subjectListEntry.siteState), " +
            "\(radiusMailing.subjectListEntry.siteZipcode) "
        selectedLocationAddress1 = radiusMailing.subjectListEntry.siteAddressLine1
        selectedLocationAddress2 = radiusMailing.subjectListEntry.siteAddressLine2 ?? " "
        selectedLocationCity = radiusMailing.subjectListEntry.siteCity
        selectedLocationState = radiusMailing.subjectListEntry.siteState
        selectedLocationZipcode = radiusMailing.subjectListEntry.siteZipcode
    }

    func maybeInitializeMapWithCurrentLocation() {
        latitude = location?.coordinate.latitude ?? 0
        longitude = location?.coordinate.longitude ?? 0
    }

    func getPlacesFromQuery(locationQuery: String,
                            completion: @escaping (_ places: [GMSAutocompletePrediction]?) -> Void = { _ in }) {
        let filter = GMSAutocompleteFilter()
        filter.type = .address

        placesClient.findAutocompletePredictions(
            fromQuery: locationQuery,
            filter: filter,
            sessionToken: GMSAutocompleteSessionToken.init()
        ) {[weak self] (results, error) in
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
        placesClient.lookUpPlaceID(placeID) {[weak self] (place, error) in
            if let error = error {
                print("lookup place id query error: \(error.localizedDescription)")
                return
            }

            guard let place = place else {
                print("No place details for \(placeID)")
                return
            }

            let streetNumber = place.addressComponents?.first(where: { $0.types.contains("street_number") })?.name ?? ""
            let streetName = place.addressComponents?.first(where: { $0.types.contains("route") })?.name ?? ""

            self?.latitude = place.coordinate.latitude
            self?.longitude = place.coordinate.longitude
            self?.selectedLocationAddress1 = "\(streetNumber) \(streetName)"
            self?.selectedLocationCity = place.addressComponents?.first(where: {
                                                                            $0.types.contains("locality") })?.shortName ?? ""
            self?.selectedLocationState = place.addressComponents?.first(where: {
                                                                            $0.types.contains("administrative_area_level_1") })?.shortName ?? ""
            self?.selectedLocationZipcode = place.addressComponents?.first(where: {
                                                                            $0.types.contains("postal_code") })?.name ?? ""
        }
    }

    func resetPlacesList() {
        places = [GMSAutocompletePrediction]()
    }

    func getRadiusMailingCoverImageOptions() {
        loadingImages = true
        addressableDataFetcher.getMailingCoverImages()
            .map { resp in
                resp.mailingCoverImages.filter({
                    $0.mailingCoverImage.cardFrontImageUrl != nil &&
                        $0.mailingCoverImage.id != nil &&
                        $0.mailingCoverImage.isDefaultCoverImage != nil
                }).map { $0.mailingCoverImage }
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] value in
                    guard let self = self else { return }
                    switch value {
                    case .failure(let error):
                        print("getRadiusMailingCoverArtOptions() receiveCompletion error: \(error)")
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
        for image in coverImages {
            guard let urlString = image.cardFrontImageUrl,
                  let url = URL(string: urlString) else { continue }

            let task = URLSession.shared.dataTask(with: url) { data, _, _ in
                guard let data = data else { return }

                DispatchQueue.main.async {[weak self] in
                    guard let self = self else { return }
                    self.mailingCoverImages[image.id!] = MailingCoverImageData(
                        id: image.id!,
                        image: image,
                        imageData: data)
                    // Present images when they've all loaded
                    if self.mailingCoverImages.keys.count == coverImages.count {
                        self.loadingImages = false
                        self.selectedCoverImageID = self.mailingCoverImages.keys.first(where: {
                            self.mailingCoverImages[$0]!.image.isDefaultCoverImage!
                        }) ?? 0
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
                    self.loadingInsideCardPreview = false
                }
            }
        }
        task.resume()
    }

    func getRadiusMailingMultiTouchTopics() {
        loadingTopics = true
        addressableDataFetcher.getMultiTouchTopics()
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
                    guard multiTouchTopics.count > 0 else {
                        self.loadingTopics = false
                        self.topics = []
                        self.topicSelectionID = 0
                        return
                    }
                    self.topics = multiTouchTopics
                    guard self.touchOneMailing?.topicSelectionID == nil else {
                        self.topicSelectionID = self.touchOneMailing!.topicSelectionID!

                        if let previouslySelectedTopic = multiTouchTopics.first(where: {
                            $0.id == self.touchOneMailing!.topicSelectionID!
                        }) {
                            self.getMessageTemplates(for: previouslySelectedTopic)
                        } else {
                            print("Could not find previouslySelectedTopic in getRadiusMailingMultiTouchTopics()")
                        }
                        return
                    }
                    self.topicSelectionID = self.topics[0].id
                    self.getMessageTemplates(for: self.topics[0])
                })
            .store(in: &disposables)
    }

    func getMessageTemplates(for topic: MultiTouchTopic) {
        let templateId = touchOneMailing?.topicSelectionID != self.topicSelectionID ||
            touchOneMailing?.topicSelectionID == nil ?
            topic.touchOneTemplateID : touchOneMailing!.customNoteTemplateID!

        getMessageTemplate(for: 1, with: templateId)
        getMessageTemplate(for: 2, with: topic.touchTwoTemplateID)
    }

    func getMessageTemplate(
        for touch: Int,
        with id: Int,
        completion: @escaping (MessageTemplate?) -> Void = { _ in }
    ) {
        addressableDataFetcher.getMessageTemplate(for: id)
            .map { resp in
                resp.messageTemplate
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] value in
                    guard let self = self else { return }
                    switch value {
                    case .failure(let error):
                        print("getMessageTemplate(for touch: \(touch), with id: \(id) receiveCompletion error: \(error)")
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
                receiveValue: { [weak self] template in
                    guard let self = self else { return }
                    if touch == 1 {
                        self.touchOneTemplate = template
                        self.touchOneBody = template.body
                        if template.mergeVars.count > 0 {
                            for mergeVarName in template.mergeVars {
                                self.touchOneTemplateMergeVariables[mergeVarName] = ""
                            }
                        } else {
                            self.touchOneTemplateMergeVariables = [:]
                        }
                    } else {
                        self.touchTwoTemplate = template
                        self.touchTwoBody = template.body
                        if template.mergeVars.count > 0 {
                            for mergeVarName in template.mergeVars {
                                self.touchTwoTemplateMergeVariables[mergeVarName] = ""
                            }
                        } else {
                            self.touchTwoTemplateMergeVariables = [:]
                        }
                        self.loadingTopics = false
                    }
                    completion(template)
                })
            .store(in: &disposables)
    }

    func createRadiusMailing(completion: @escaping (_ updatedMailing: RadiusMailing?) -> Void) {
        guard let encodedNewRadiusData = try? JSONEncoder().encode(
            OutgoingNewRadiusMailingWrapper(
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

        addressableDataFetcher.createNewRadiusMailing(encodedNewRadiusData)
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
        completion: @escaping (_ updatedMailing: RadiusMailing?) -> Void
    ) {

        guard let radiusMailingID = touchOneMailing?.id else {
            print("No Radius Mailing Selected")
            return
        }

        addressableDataFetcher.updateRadiusMailing(
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
                if radiusMailingComponent == .list {
                    self.touchTwoMailing = mailing
                    self.getMailingWithCardInsidePreview(with: mailing.id, for: .touchTwo)
                    self.getMailingWithCardInsidePreview(with: self.touchOneMailing!.id, for: .touchOne)

                } else {
                    self.touchOneMailing = mailing
                }
                completion(mailing)
            })
        .store(in: &disposables)
    }

    private func getEncodedUpdateRadiusMailingData(component: RadiusMailingComponent) -> Data? {
        switch component {
        case .location:
            guard let updateData = try? JSONEncoder().encode(
                OutgoingNewRadiusMailingWrapper(subjectListEntry:
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
                OutgoingRadiusMailingCoverArtWrapper(cover: OutgoingRadiusMailingCoverArtData(layoutTemplateID: selectedCoverImageID))
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
                        shouldEditTouchOneTemplate: shouldUpdateTouchOneTemplate,
                        templateOneBody: touchOneBody,
                        templateTwoBody: touchTwoBody),
                    mergeVars: touchOneTemplateMergeVariables.merging(
                        touchTwoTemplateMergeVariables, uniquingKeysWith: { (first, _) in first }))
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

    func updateListEntry(for id: Int, with status: String) {
        guard let encodedUpdateListEntryData = try? JSONEncoder().encode(
            OutgoingRecipientStatus(status: status)
        ) else {
            print("Update List Entry Encoding Error")
            return
        }

        addressableDataFetcher.updateRadiusListEntry(for: id, encodedUpdateListEntryData)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { value in
                    switch value {
                    case .failure(let error):
                        print("updateListEntry(for id: \(id), with status: \(status), receiveCompletion error: \(error)")
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] _ in
                    guard let self = self else { return }
                    guard let currentRadiusMailing = self.touchOneMailing else { return }
                    // Update list of recipients
                    self.getRadiusMailing(with: currentRadiusMailing.id) { updatedMailing in
                        self.touchOneMailing = updatedMailing
                    }
                })
            .store(in: &disposables)
    }

    private func getRadiusMailing(with id: Int, completion: @escaping (RadiusMailing?) -> Void) {
        addressableDataFetcher.getSelectedRadiusMailing(for: id)
            .map { $0.radiusMailing }
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

    private func getMailingWithCardInsidePreview(with id: Int, for touch: AddressableTouch) {
        addressableDataFetcher.getSelectedRadiusMailing(for: id)
            .map { $0.radiusMailing }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { value in
                    switch value {
                    case .failure(let error):
                        print("getMailingWithCardInsidePreview(for id: \(id), for touch: \(touch), receiveCompletion error: \(error)")
                    case .finished:
                        break
                    }
                },
                receiveValue: {radiusMailing in
                    // Recurssively get mailing until illustrator_job_queue is finished building card inside preview image
                    guard let insideCardPreviewUrl = radiusMailing.cardInsidePreviewUrl else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                            self.getMailingWithCardInsidePreview(with: radiusMailing.id, for: touch)
                        }
                        return
                    }
                    if touch == .touchOne {
                        self.getInsideCardImageData(for: .touchOne, url: insideCardPreviewUrl)
                    } else {
                        self.getInsideCardImageData(for: .touchTwo, url: insideCardPreviewUrl)
                    }
                })
            .store(in: &disposables)
    }

    func updateMessageTemplate(
        for touch: AddressableTouch,
        id: Int,
        with newBody: String,
        completion: @escaping (UpdatedMessageTemplate?) -> Void) {
        guard let encodedMessageTemplateData = try? JSONEncoder().encode(
            OutgoingMessageTemplateWrapper(messageTemplate: OutgoingMessageTemplate(title: nil, body: newBody))
        ) else {
            print("Update Message Template Encoding Error")
            return
        }

        addressableDataFetcher.updateMessageTemplate(for: id, encodedMessageTemplateData)
            .map { resp in
                resp.messageTemplate
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { value in
                    switch value {
                    case .failure(let error):
                        print("updateMessageTemplate(for id: \(id), with newBody: \(newBody), receiveCompletion error: \(error)")
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

    func createMessageTemplate(
        for touch: AddressableTouch,
        with newBody: String,
        completion: @escaping (NewMessageTemplate?) -> Void) {

        guard let selectedMailing = touchOneMailing,
              let encodedMessageTemplateData = try? JSONEncoder().encode(
                OutgoingMessageTemplateWrapper(messageTemplate: OutgoingMessageTemplate(
                    title: "\(selectedMailing.subjectListEntry.siteAddressLine1) \(touch.rawValue) ",
                    body: newBody
                ))
              ) else {
            print("Create Message Template Encoding Error")
            return
        }

        addressableDataFetcher.createMessageTemplate(encodedMessageTemplateData)
            .map { resp in
                resp.messageTemplate
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { value in
                    switch value {
                    case .failure(let error):
                        print("createMessageTemplate(with data: \(encodedMessageTemplateData), receiveCompletion error: \(error)")
                        completion(nil)
                    case .finished:
                        break
                    }
                },
                receiveValue: { newMessageTemplate in
                    completion(newMessageTemplate)
                })
            .store(in: &disposables)
    }

    func setSelectedDropDate(selectedDate: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        selectedDropDate = dateFormatter.string(from: selectedDate)
    }

    func getDataTreeDefaultSearchCriteria() {
        addressableDataFetcher.getDefaultDataTreeSearchCriteria()
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
}

extension ComposeRadiusMailingViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.location = location
    }
}
