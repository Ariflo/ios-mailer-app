//
//  ProfileViewModel.swift
//  Addressable
//
//  Created by Ari on 5/19/21.
//

import SwiftUI
import Combine

// swiftlint:disable type_body_length
class ProfileViewModel: ObservableObject {
    @Published var account: Account?
    @Published var handwritings: [Handwriting] = []
    @Published var loadingHandwritings: Bool = false
    @Published var loadingUserAccount: Bool = false
    @Published var loadingUserAddress: Bool = false
    @Published var loadingIsPrimary: Bool = false

    @Published var userFirstName: String = ""
    @Published var userLastName: String = ""
    @Published var userBusinessName: String = ""
    @Published var userAddressLine1: String = ""
    @Published var userAddressLine2: String = ""
    @Published var userCity: String = ""
    @Published var userState: String = ""
    @Published var userZipcode: String = ""
    @Published var dre: String = ""

    @Published var isPrimaryUser: Bool = false

    private let apiService: ApiService
    private var disposables = Set<AnyCancellable>()

    let analyticsTracker: AnalyticsTracker

    init(provider: DependencyProviding) {
        self.apiService = provider.register(provider: provider)
        analyticsTracker = provider.register(provider: provider)
    }

    func logout(onCompletion: @escaping (GenericAPISuccessResponse?) -> Void) {
        guard let keyStoreDeviceId = KeyChainServiceUtil.shared[latestDeviceID],
              let encodedDeviceIdData = try? JSONEncoder().encode(
                DeviceIDWrapper(deviceID: keyStoreDeviceId)
              ) else {
            print("DeviceId Encoding Error In ProfileView")
            return
        }

        apiService.logoutMobileUser(with: encodedDeviceIdData)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { value in
                    switch value {
                    case .failure(let error):
                        print("logout() receiveCompletion error: \(error)")
                        onCompletion(nil)
                    case .finished:
                        break
                    }
                },
                receiveValue: { logoutResponse in
                    onCompletion(logoutResponse)
                })
            .store(in: &disposables)
    }

    func getUserAccount() {
        guard let keyStoreUser = KeyChainServiceUtil.shared[userData],
              let prevUserData = keyStoreUser.data(using: .utf8),
              let user = try? JSONDecoder().decode(User.self, from: prevUserData) else {
            print("updateUserHandwritingStyle() keystore user fetch error")
            return
        }

        loadingUserAccount = true
        apiService.getAccount(with: user.accountID)
            .map { $0.account }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] value in
                    guard let self = self else { return }
                    switch value {
                    case .failure(let error):
                        print("getUserAccount() receiveCompletion error: \(error)")
                        self.loadingUserAccount = false
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] accountData in
                    guard let self = self else { return }
                    self.account = accountData
                    self.loadingUserAccount = false
                })
            .store(in: &disposables)
    }

    func getAllHandwritings() {
        loadingHandwritings = true

        apiService.getAccountHandwritingStyles()
            .map { $0.handwritings }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] value in
                    guard let self = self else { return }
                    switch value {
                    case .failure(let error):
                        print("getAllHandwritings() receiveCompletion error: \(error)")
                        self.loadingHandwritings = false
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] handwritings in
                    guard let self = self else { return }
                    self.handwritings = handwritings
                    self.loadingHandwritings = false
                })
            .store(in: &disposables)
    }

    func updateUserHandwritingStyle(to handwritingId: Int) {
        guard let keyStoreUser = KeyChainServiceUtil.shared[userData],
              let prevUserData = keyStoreUser.data(using: .utf8),
              let user = try? JSONDecoder().decode(User.self, from: prevUserData) else {
            print("updateUserHandwritingStyle() keystore user fetch error")
            return
        }

        guard let encodedUpdateUserData = try? JSONEncoder().encode(
            UpdateHandwriting(handwritingID: handwritingId)
        ) else {
            print("UpdateHandwriting Encoding Error")
            return
        }
        loadingHandwritings = true
        apiService.updateUser(with: user.id, updateUserData: encodedUpdateUserData)
            .map { $0.user }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] value in
                    guard let self = self else { return }
                    switch value {
                    case .failure(let error):
                        print("updateUserHandwritingStyle() receiveCompletion error: \(error)")
                        self.loadingHandwritings = false
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] updatedUser in
                    guard let self = self else { return }
                    guard let encodedCurrentUserData = try? JSONEncoder().encode(updatedUser) else {
                        print("encodedCurrentUserData Encoding Error")
                        return
                    }
                    KeyChainServiceUtil.shared[userData] = String(data: encodedCurrentUserData, encoding: .utf8)
                    self.loadingHandwritings = false
                })
            .store(in: &disposables)
    }

    func updateUserAddress() {
        guard let keyStoreUser = KeyChainServiceUtil.shared[userData],
              let prevUserData = keyStoreUser.data(using: .utf8),
              let user = try? JSONDecoder().decode(User.self, from: prevUserData) else {
            print("updateUserHandwritingStyle() keystore user fetch error")
            return
        }

        guard let encodedUpdateUserData = try? JSONEncoder().encode(
            UpdateUserAddress(
                firstName: userFirstName,
                lastName: userLastName,
                dre: dre,
                companyName: userBusinessName,
                addressLine1: userAddressLine1,
                addressLine2: userAddressLine2,
                city: userCity,
                state: userState,
                zipcode: userZipcode
            )
        ) else {
            print("UpdateUserAddress Encoding Error")
            return
        }
        loadingUserAddress = true
        apiService.updateUser(with: user.id, updateUserData: encodedUpdateUserData)
            .map { $0.user }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] value in
                    guard let self = self else { return }
                    switch value {
                    case .failure(let error):
                        print("updateUserAddress() receiveCompletion error: \(error)")
                        self.loadingUserAddress = false
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] updatedUser in
                    guard let self = self else { return }
                    guard let encodedCurrentUserData = try? JSONEncoder().encode(updatedUser) else {
                        print("encodedCurrentUserData Encoding Error")
                        return
                    }
                    KeyChainServiceUtil.shared[userData] = String(data: encodedCurrentUserData, encoding: .utf8)
                    self.loadingUserAddress = false
                })
            .store(in: &disposables)
    }

    func populateFields() {
        guard let keyStoreUser = KeyChainServiceUtil.shared[userData],
              let prevUserData = keyStoreUser.data(using: .utf8),
              let user = try? JSONDecoder().decode(User.self, from: prevUserData) else {
            print("updateUserHandwritingStyle() keystore user fetch error")
            return
        }

        userFirstName = user.firstName
        userLastName = user.lastName
        userBusinessName = user.companyName ?? ""
        userAddressLine1 = user.addressLine1
        userAddressLine2 = user.addressLine2 ?? ""
        userCity = user.city
        userState = user.state
        userZipcode = user.zipcode
        dre = user.dre ?? ""
    }

    func verifyMobileRegistration(completion: @escaping (MobileIdentityResponse?) -> Void) {
        loadingIsPrimary = true
        if let deviceId = KeyChainServiceUtil.shared[latestDeviceID] {
            apiService.verifyMobileIdentity(with: deviceId)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { value in
                        switch value {
                        case .failure(let error):
                            completion(nil)
                            print("verifyMobileRegistration() ProfileViewModel(), receiveCompletion error: \(error)")
                        case .finished:
                            break
                        }
                    },
                    receiveValue: { mobileIdentityResponse in
                        completion(mobileIdentityResponse)
                    })
                .store(in: &disposables)
        }
    }

    func updateIsPrimary() {
        guard let encodedIsPrimaryData = try? JSONEncoder().encode(
            UpdateMobileIdentityWrapper(mobileIdentity: UpdatedMobileIdentity(isPrimary: isPrimaryUser))
        ) else {
            print("UpdateUserIsPrimary Encoding Error")
            return
        }
        guard let keyStoreDeviceId = KeyChainServiceUtil.shared[latestDeviceID] else { return }
        loadingIsPrimary = true
        apiService.updateUserIsPrimary(with: keyStoreDeviceId, isPrimaryData: encodedIsPrimaryData)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] value in
                    guard let self = self else { return }
                    switch value {
                    case .failure(let error):
                        print("updateIsPrimary() receiveCompletion error: \(error)")
                        self.loadingIsPrimary = false
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] _ in
                    guard let self = self else { return }
                    self.loadingIsPrimary = false
                })
            .store(in: &disposables)
    }
}
