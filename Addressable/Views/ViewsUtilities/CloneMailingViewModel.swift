//
//  CloneMailingViewModel.swift
//  Addressable
//
//  Created by Ari on 8/3/21.
//

import SwiftUI
import Combine

class CloneMailingViewModel: ObservableObject {
    private let apiService: ApiService
    private var disposables = Set<AnyCancellable>()

    @Binding var mailing: Mailing

    @Published var mailingName: String = ""
    @Published var targetDropDate: String = ""
    @Published var targetQuantity: String = ""
    @Published var isEditingTargetDropDate: Bool = false
    @Published var useLayoutTemplate: Bool = true
    @Published var useMessageTemplate: Bool = true
    @Published var useAudienceList: Bool = true

    init(provider: DependencyProviding, selectedMailing: Binding<Mailing>) {
        apiService = provider.register(provider: provider)

        mailingName = selectedMailing.wrappedValue.name + " - COPY"
        targetQuantity = String(selectedMailing.wrappedValue.targetQuantity)
        _mailing = selectedMailing

        // Initialize TargetDropDate to current day + ten
        if let datePlusTen = Calendar.current.date(byAdding: .day, value: 10, to: Date()) {
            setSelectedDropDate(selectedDate: datePlusTen)
        }
    }

    func setSelectedDropDate(selectedDate: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        targetDropDate = dateFormatter.string(from: selectedDate)
    }

    func cloneMailing(completion: @escaping (Mailing?) -> Void) {
        let listUploadIDS = useAudienceList ?
            mailing.listUploadIdToNameMap.reduce([]) { listUploadIds, audienceMap in
                listUploadIds + audienceMap.keys
            } : []
        guard let quantity = Int(targetQuantity) else {
            print("Encoding Error in cloneMailing() targetQuantity is not a number")
            return
        }
        guard let cloneMailingData = try? JSONEncoder().encode(
            CloneMailingWrapper(
                cloneMailing:
                    CloneMailing(
                        name: mailingName,
                        targetDropDate: targetDropDate,
                        targetQuantity: quantity,
                        useLayoutTemplate: useLayoutTemplate ? 1 : 0,
                        useMessageTemplate: useMessageTemplate ? 1 : 0,
                        listUploadIDS: listUploadIDS
                    )
            )
        ) else {
            print("Encoding Error in cloneMailing()")
            return
        }
        apiService.cloneMailing(
            accountId: mailing.account.id,
            mailingId: mailing.id,
            cloneMailingData: cloneMailingData
        )
        .map { $0.mailing }
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { value in
                switch value {
                case .failure(let error):
                    print("cloneMailing() receiveCompletion error: \(error)")
                    completion(nil)
                case .finished:
                    break
                }
            },
            receiveValue: { clonedMailing in
                completion(clonedMailing)
            })
        .store(in: &disposables)
    }
}
