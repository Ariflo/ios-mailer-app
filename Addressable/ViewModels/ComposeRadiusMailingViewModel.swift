//
//  ComposeRadiusMailingViewModel.swift
//  Addressable
//
//  Created by Ari on 2/12/21.
//

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
    var currentRadiusMailingID: Int?

    @Published var selectedLocationAddress1 = ""
    @Published var selectedLocationAddress2 = ""
    @Published var selectedLocationCity = ""
    @Published var selectedLocationState = ""
    @Published var selectedLocationZipcode = ""

    @Published var step = ComposeRadiusMailingSteps.selectLocation
    @Published var locationEntry: String = ""
    @Published var selectedCoverArtID: Int?
    @Published var mailingArt: [MailingCoverArt] = []
    @Published var topics: [MultiTouchTopic] = []
    @Published var topicSelectionID: Int = 0
    @Published var touch1Body: String = "Write your message here..."
    @Published var touch2Body: String = "Write your message here..."
    @Published var numOfWeeksSelection: Int = 3
    @Published var weekOptions: [(String, Int)] = [("1 Week", 1), ("2 Weeks", 2), ("3 Weeks", 3), ("4 Weeks", 4), ("5 Weeks", 5), ("6 Weeks", 6)]
    @Published var touch1MergeVars: [String: String] = [:]
    @Published var touch2MergeVars: [String: String] = [:]
    @Published var selectedRadiusMailing: RadiusMailing?

    init(selectedRadiusMailing: RadiusMailing?) {
        super.init()

        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()

        self.selectedRadiusMailing = selectedRadiusMailing
        self.currentRadiusMailingID = selectedRadiusMailing?.parentMailingID
    }

    func maybeInitializeMapWithCurrentLocation() {
        latitude = location?.coordinate.latitude ?? 0
        longitude = location?.coordinate.longitude ?? 0
    }

    func getPlacesFromQuery(locationQuery: String) {
        let filter = GMSAutocompleteFilter()
        filter.type = .address

        placesClient.findAutocompletePredictions(fromQuery: locationQuery, filter: filter, sessionToken: GMSAutocompleteSessionToken.init()) {[weak self] (results, error) in
            if let error = error {
                print("Autocomplete error: \(error)")
                return
            }
            if let results = results {
                self?.places = results
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
            self?.selectedLocationCity = place.addressComponents?.first(where: { $0.types.contains("locality") })?.shortName ?? ""
            self?.selectedLocationState = place.addressComponents?.first(where: { $0.types.contains("administrative_area_level_1") })?.shortName ?? ""
            self?.selectedLocationZipcode = place.addressComponents?.first(where: { $0.types.contains("postal_code") })?.name ?? ""
        }
    }

    func resetPlacesList() {
        places = [GMSAutocompletePrediction]()
    }

    func getRadiusMailingCoverArtOptions() {
        addressableDataFetcher.getMailingCoverArt()
            .map { resp in
                resp.mailingCoverArts.map { $0.mailingCoverArt }
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] value in
                    guard let self = self else { return }
                    switch value {
                    case .failure(let error):
                        print("getRadiusMailingCoverArtOptions() receiveCompletion error: \(error)")
                        self.mailingArt = []
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] mailingArtOptions in
                    guard let self = self else { return }
                    self.mailingArt = mailingArtOptions
                })
            .store(in: &disposables)
    }

    func getRadiusMailingMultiTouchTopics() {
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
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] multiTouchTopics in
                    guard let self = self else { return }
                    guard multiTouchTopics.count > 0 else {
                        self.topics = []
                        self.topicSelectionID = 0
                        return
                    }
                    self.topics = multiTouchTopics
                    self.topicSelectionID = self.topics[0].id
                    self.numOfWeeksSelection = self.topics[0].touchDuration
                    self.getMessageTemplates(for: self.topics[0])
                })
            .store(in: &disposables)
    }

    func getMessageTemplates(for topic: MultiTouchTopic) {
        getMessageTemplate(for: 1, with: topic.touchOneTemplateID)
        getMessageTemplate(for: 2, with: topic.touchTwoTemplateID)
    }

    private func getMessageTemplate(for touch: Int, with id: Int) {
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
                            self.touch1Body = "Write your message here..."
                            self.touch1MergeVars = [:]
                        } else {
                            self.touch2Body = "Write your message here..."
                            self.touch2MergeVars = [:]
                        }
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] template in
                    guard let self = self else { return }
                    if touch == 1 {
                        self.touch1Body = template.body
                        self.touch1MergeVars = template.mergeVars
                    } else {
                        self.touch2Body = template.body
                        self.touch2MergeVars = template.mergeVars
                    }
                })
            .store(in: &disposables)
    }

    func createRadiusMailing(completion: @escaping (_ updatedMailing: RadiusMailing?) -> Void) {
        guard let encodedNewRadiusData = try? JSONEncoder().encode(
            OutgoingSubjectListEntryWrapper(subjectListEntry:
                                                OutgoingSubjectListEntry(
                                                    siteAddressLine1: selectedLocationAddress1,
                                                    siteAddressLine2: selectedLocationAddress2,
                                                    siteCity: selectedLocationCity,
                                                    siteState: selectedLocationState,
                                                    siteZipcode: selectedLocationZipcode,
                                                    latitude: String(latitude),
                                                    longitude: String(longitude),
                                                    status: "active_radius_subject")
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
                    self.currentRadiusMailingID = newRadiusMailing.parentMailingID
                    completion(newRadiusMailing)
                })
            .store(in: &disposables)
    }

    func updateRadiusMailingData(
        for radiusMailingComponent: RadiusMailingComponent,
        with radiusMailingUpdate: OutgoingRadiusMailing,
        completion: @escaping (_ updatedMailing: RadiusMailing?) -> Void
    ) {

        guard let radiusMailingID = currentRadiusMailingID else {
            print("No Current Radius Mailing Selected")
            return
        }

        addressableDataFetcher.updateRadiusMailing(
            for: radiusMailingComponent,
            with: radiusMailingID,
            getEncodedUpdateRadiusMailingData(
                component: radiusMailingComponent,
                radiusMailingUpdate: radiusMailingUpdate)
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
                completion(mailing)
            })
        .store(in: &disposables)
    }

    private func getEncodedUpdateRadiusMailingData(component: RadiusMailingComponent, radiusMailingUpdate: OutgoingRadiusMailing) -> Data? {
        switch component {
        case .cover:
            guard let updateData = try? JSONEncoder().encode(
                OutgoingRadiusMailingCoverArtWrapper(cover: OutgoingRadiusMailingCoverArtData(layoutTemplateID: radiusMailingUpdate.layoutTemplateID!))
            ) else {
                print("Update Radius Mailing COVER Encoding Error")
                return nil
            }
            return updateData
        case .topic:
            guard let updateData = try? JSONEncoder().encode(
                OutgoingRadiusMailingTopicWrapper(
                    topic: OutgoingRadiusMailingTopicData(
                        multiTouchTopicID: radiusMailingUpdate.multiTouchTopicID!,
                        templateOneBody: radiusMailingUpdate.templateOneBody!,
                        templateTwoBody: radiusMailingUpdate.templateTwoBody!,
                        mergeVars: radiusMailingUpdate.mergeVars!,
                        touchDuration: radiusMailingUpdate.touchDuration!))
            ) else {
                print("Update Radius Mailing TOPIC Encoding Error")
                return nil
            }
            return updateData
        case .list:
            guard let updateData = try? JSONEncoder().encode(
                OutgoingRadiusMailingListWrapper(multiTouchTopic: OutgoingRadiusMailingListData(touchTwoWeeks: radiusMailingUpdate.touchDurationConfirmation!))
            ) else {
                print("Update Radius Mailing Encoding Error")
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
                    guard let currentRadiusMailing = self.selectedRadiusMailing else { return }
                    // Update list of recipients
                    self.getUpdatedRadiusMailing(for: currentRadiusMailing.parentMailingID)
                })
            .store(in: &disposables)
    }

    func getUpdatedRadiusMailing(for id: Int) {
        addressableDataFetcher.getSelectedRadiusMailing(for: id)
            .map { $0.radiusMailing }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { value in
                    switch value {
                    case .failure(let error):
                        print("getRadiusMailing(for id: \(id)), receiveCompletion error: \(error)")
                    case .finished:
                        break
                    }
                },
                receiveValue: {[weak self] radiusMailing in
                    guard let self = self else { return }
                    self.selectedRadiusMailing = radiusMailing
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
